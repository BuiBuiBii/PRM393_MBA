import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../storage/token_storage.dart';

enum ChatSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

typedef ChatSocketEventHandler = void Function(Map<String, dynamic> event);
typedef ChatSocketErrorHandler = void Function(ChatSocketIssue issue);

final chatSocketClientProvider = Provider<ChatSocketClient>((ref) {
  final client = ChatSocketClient(ref.watch(tokenStorageProvider));
  ref.onDispose(client.dispose);
  return client;
});

final chatSocketStatusProvider = StreamProvider<ChatSocketStatus>((ref) async* {
  final client = ref.watch(chatSocketClientProvider);
  yield client.status;
  yield* client.statuses;
});

class ChatSocketIssue {
  const ChatSocketIssue({required this.code, required this.message});

  final String code;
  final String message;
}

class ChatSocketClient {
  ChatSocketClient(this._tokenStorage);

  final TokenStorageReader _tokenStorage;
  final Map<String, int> _roomReferences = {};
  final Map<String, Set<ChatSocketErrorHandler>> _roomErrorHandlers = {};
  final StreamController<ChatSocketStatus> _statusController =
      StreamController<ChatSocketStatus>.broadcast();

  io.Socket? _socket;
  String? _activeToken;
  ChatSocketStatus _status = ChatSocketStatus.disconnected;

  ChatSocketStatus get status => _status;
  Stream<ChatSocketStatus> get statuses => _statusController.stream;

  Future<ChatSocketBinding?> bindSession({
    required String sessionId,
    required ChatSocketEventHandler onMessageCreated,
    required ChatSocketEventHandler onSessionUpdated,
    required ChatSocketEventHandler onTyping,
    required ChatSocketEventHandler onReadUpdated,
    ChatSocketErrorHandler? onError,
  }) async {
    if (sessionId.isEmpty || AppConfig.demoMode) return null;
    final socket = await _ensureSocket();
    if (socket == null) {
      onError?.call(
        const ChatSocketIssue(
          code: 'UNAUTHORIZED',
          message: 'Không có access token cho kết nối realtime.',
        ),
      );
      return null;
    }

    void messageHandler(dynamic payload) =>
        _dispatchForSession(payload, sessionId, onMessageCreated);
    void sessionHandler(dynamic payload) =>
        _dispatchForSession(payload, sessionId, onSessionUpdated);
    void typingHandler(dynamic payload) =>
        _dispatchForSession(payload, sessionId, onTyping);
    void readHandler(dynamic payload) =>
        _dispatchForSession(payload, sessionId, onReadUpdated);

    socket.on('chat:message_created', messageHandler);
    socket.on('chat:session_updated', sessionHandler);
    socket.on('chat:typing', typingHandler);
    socket.on('chat:read_updated', readHandler);

    _roomReferences.update(sessionId, (count) => count + 1, ifAbsent: () => 1);
    if (onError != null) {
      _roomErrorHandlers
          .putIfAbsent(sessionId, () => <ChatSocketErrorHandler>{})
          .add(onError);
    }
    if (socket.connected) {
      _join(sessionId);
    } else {
      _setStatus(ChatSocketStatus.connecting);
      socket.connect();
    }

    return ChatSocketBinding._(
      dispose: () {
        socket.off('chat:message_created', messageHandler);
        socket.off('chat:session_updated', sessionHandler);
        socket.off('chat:typing', typingHandler);
        socket.off('chat:read_updated', readHandler);
        if (onError != null) {
          final handlers = _roomErrorHandlers[sessionId];
          handlers?.remove(onError);
          if (handlers?.isEmpty == true) _roomErrorHandlers.remove(sessionId);
        }
        final remaining = (_roomReferences[sessionId] ?? 1) - 1;
        if (remaining <= 0) {
          _roomReferences.remove(sessionId);
          if (socket.connected) {
            socket.emitWithAck('chat:leave', {'sessionId': sessionId});
          }
          if (_roomReferences.isEmpty) socket.disconnect();
        } else {
          _roomReferences[sessionId] = remaining;
        }
      },
    );
  }

  void sendTyping(String sessionId, bool isTyping) {
    final socket = _socket;
    if (socket?.connected != true || !_roomReferences.containsKey(sessionId)) {
      return;
    }
    socket!.emit('chat:typing', {
      'sessionId': sessionId,
      'isTyping': isTyping,
    });
  }

  void markRead(String sessionId) {
    final socket = _socket;
    if (socket?.connected != true || !_roomReferences.containsKey(sessionId)) {
      return;
    }
    socket!.emitWithAck('chat:read', {'sessionId': sessionId});
  }

  Future<io.Socket?> _ensureSocket() async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      _setStatus(ChatSocketStatus.error);
      return null;
    }
    if (_socket != null && _activeToken == token) return _socket;

    _socket?.dispose();
    _activeToken = token;
    _setStatus(ChatSocketStatus.connecting);
    final socket = io.io(
      AppConfig.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) {
      _setStatus(ChatSocketStatus.connected);
      for (final sessionId in _roomReferences.keys) {
        _join(sessionId);
      }
    });
    socket.onDisconnect((_) => _setStatus(ChatSocketStatus.disconnected));
    socket.onConnectError((error) {
      _setStatus(ChatSocketStatus.error);
      _notifyAll(_issueFrom(error, fallbackCode: 'CONNECT_ERROR'));
    });
    socket.io.on('reconnect_attempt', (_) {
      _setStatus(ChatSocketStatus.reconnecting);
    });
    return socket;
  }

  void _join(String sessionId) {
    _socket?.emitWithAck(
      'chat:join',
      {'sessionId': sessionId},
      ack: (dynamic response) {
        if (response is Map && response['success'] == true) {
          _socket?.emitWithAck('chat:read', {'sessionId': sessionId});
          return;
        }
        _notifyRoom(
          sessionId,
          _issueFrom(response, fallbackCode: 'JOIN_FAILED'),
        );
      },
    );
  }

  ChatSocketIssue _issueFrom(dynamic payload, {required String fallbackCode}) {
    final map = payload is Map ? Map<String, dynamic>.from(payload) : null;
    final error = map?['error'];
    final errorMap = error is Map ? Map<String, dynamic>.from(error) : null;
    return ChatSocketIssue(
      code: (errorMap?['code'] ?? map?['code'] ?? fallbackCode).toString(),
      message: (errorMap?['message'] ??
              map?['message'] ??
              payload?.toString() ??
              'Không thể kết nối realtime.')
          .toString(),
    );
  }

  void _notifyRoom(String sessionId, ChatSocketIssue issue) {
    for (final handler in List<ChatSocketErrorHandler>.of(
        _roomErrorHandlers[sessionId] ?? {})) {
      handler(issue);
    }
  }

  void _notifyAll(ChatSocketIssue issue) {
    for (final sessionId in _roomErrorHandlers.keys.toList()) {
      _notifyRoom(sessionId, issue);
    }
  }

  void _dispatchForSession(
    dynamic payload,
    String sessionId,
    ChatSocketEventHandler handler,
  ) {
    if (payload is! Map) return;
    final event = Map<String, dynamic>.from(payload);
    if (event['sessionId']?.toString() != sessionId) return;
    handler(event);
  }

  void _setStatus(ChatSocketStatus next) {
    _status = next;
    if (!_statusController.isClosed) _statusController.add(next);
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _roomReferences.clear();
    _roomErrorHandlers.clear();
    _statusController.close();
  }
}

class ChatSocketBinding {
  ChatSocketBinding._({required void Function() dispose}) : _dispose = dispose;

  final void Function() _dispose;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _dispose();
  }
}

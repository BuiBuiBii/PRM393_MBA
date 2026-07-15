import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_service.dart';
import '../data/chat_repository.dart';
import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/normalizers.dart';
import '../../../shared/models/app_models.dart';

class ChatState {
  const ChatState({
    this.sessions = const [],
    this.current,
    this.isLoading = false,
    this.isSending = false,
    this.error,
    this.repositoryId,
    this.roadmapId,
    this.analysisId,
    this.snapshotId,
    this.remoteTyping = false,
  });

  final List<ChatSessionModel> sessions;
  final ChatSessionModel? current;
  final bool isLoading;
  final bool isSending;
  final String? error;
  final String? repositoryId;
  final String? roadmapId;
  final String? analysisId;
  final String? snapshotId;
  final bool remoteTyping;

  ChatState copyWith({
    List<ChatSessionModel>? sessions,
    ChatSessionModel? current,
    bool clearCurrent = false,
    bool? isLoading,
    bool? isSending,
    String? error,
    bool clearError = false,
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
    bool replaceContext = false,
    bool? remoteTyping,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      current: clearCurrent ? null : (current ?? this.current),
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      repositoryId:
          replaceContext ? repositoryId : (repositoryId ?? this.repositoryId),
      roadmapId: replaceContext ? roadmapId : (roadmapId ?? this.roadmapId),
      analysisId: replaceContext ? analysisId : (analysisId ?? this.analysisId),
      snapshotId: replaceContext ? snapshotId : (snapshotId ?? this.snapshotId),
      remoteTyping: remoteTyping ?? this.remoteTyping,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late ChatRepository _repository;

  @override
  ChatState build() {
    _repository = ref.read(chatRepositoryProvider);
    return const ChatState();
  }

  void setContext(
      {String? repositoryId,
      String? roadmapId,
      String? analysisId,
      String? snapshotId}) {
    state = state.copyWith(
      repositoryId: repositoryId,
      roadmapId: roadmapId,
      analysisId: analysisId,
      snapshotId: snapshotId,
      replaceContext: true,
    );
  }

  Future<void> fetchSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = AppConfig.demoMode
          ? await DemoService.instance.getChatSessions()
          : await safeRequest(_repository.getChatSessions);

      var current = state.current;
      final synced = current != null
          ? sessions.where((s) => s.id == current!.id).firstOrNull ?? current
          : null;
      current = synced ?? (sessions.isNotEmpty ? sessions.first : null);

      if (current != null && current.id.isNotEmpty && !AppConfig.demoMode) {
        try {
          current =
              await safeRequest(() => _repository.getChatSession(current!.id));
        } catch (_) {}
      } else if (current != null &&
          current.id.isNotEmpty &&
          AppConfig.demoMode) {
        try {
          current = await DemoService.instance.getChatSession(current.id);
        } catch (_) {}
      }

      state = state.copyWith(
          sessions: sessions, current: current, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<ChatSessionModel> createSession(
    String title, {
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessionTitle =
          title.trim().isEmpty ? 'Cuộc trò chuyện mới' : title.trim();
      final session = AppConfig.demoMode
          ? await DemoService.instance.createChatSession(sessionTitle)
          : await safeRequest(
              () => _repository.createChatSession(
                ChatSessionCreatePayload(
                  title: sessionTitle,
                  repositoryId: repositoryId,
                  roadmapId: roadmapId,
                  analysisId: analysisId,
                  snapshotId: snapshotId,
                ),
              ),
            );
      if (session.id.isEmpty) {
        throw ApiException('Backend không trả session id');
      }
      state = state.copyWith(
        sessions: [session, ...state.sessions.where((s) => s.id != session.id)],
        current: session,
        isLoading: false,
        repositoryId: null,
        roadmapId: null,
        analysisId: null,
        snapshotId: null,
        replaceContext: true,
      );
      return session;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      if (!AppConfig.demoMode) {
        await safeRequest(() => _repository.deleteChatSession(id));
      }
    } catch (e) {
      if (e is! ApiException || e.statusCode != 404) rethrow;
    }

    final remaining =
        state.sessions.where((session) => session.id != id).toList();
    final wasCurrent = state.current?.id == id;
    state = state.copyWith(
      sessions: remaining,
      current: wasCurrent && remaining.isNotEmpty ? remaining.first : null,
      clearCurrent: wasCurrent && remaining.isEmpty,
      clearError: true,
    );
    if (wasCurrent && remaining.isNotEmpty) {
      await selectSession(remaining.first.id);
    }
  }

  Future<void> selectSession(String id) async {
    final cached = state.sessions.where((s) => s.id == id).firstOrNull;
    if (cached != null) {
      state = state.copyWith(current: cached, clearError: true);
    }
    try {
      final session = AppConfig.demoMode
          ? await DemoService.instance.getChatSession(id)
          : await safeRequest(() => _repository.getChatSession(id));
      state = state.copyWith(
        current: session,
        sessions: state.sessions.map((s) => s.id == id ? session : s).toList(),
        remoteTyping: false,
      );
    } catch (e) {
      state = state.copyWith(error: getApiErrorMessage(e));
    }
  }

  Future<void> sendMessage(String content) async {
    var session = state.current;
    if (session == null) {
      await createSession('Tư vấn GitHub của tôi');
      session = state.current;
    }
    if (session == null || session.id.isEmpty) {
      state = state.copyWith(
          error: 'Chat session không có id. Hãy tạo session mới.');
      return;
    }
    if (session.status == 'closed') {
      state = state.copyWith(
        error: 'Session đã đóng, bạn không thể gửi thêm tin nhắn.',
      );
      throw ApiException(
        'Session đã đóng, bạn không thể gửi thêm tin nhắn.',
        code: 'CHAT_SESSION_CLOSED',
      );
    }

    final optimistic = ChatMessageModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      senderType: 'USER',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
    final updated =
        session.copyWith(messages: [...session.messages, optimistic]);
    state = state.copyWith(current: updated, isSending: true, clearError: true);

    try {
      ChatSessionModel nextSession;
      if (AppConfig.demoMode) {
        nextSession =
            await DemoService.instance.sendChatMessage(session.id, content);
      } else {
        final sessionHasPinnedContext =
            session.repositoryId?.isNotEmpty == true ||
                session.roadmapId?.isNotEmpty == true ||
                session.analysisId?.isNotEmpty == true ||
                session.snapshotId?.isNotEmpty == true;
        final result = await safeRequest(
          () => _repository.sendChatMessage(
            session!.id,
            content,
            repositoryId: sessionHasPinnedContext ? null : state.repositoryId,
            roadmapId: sessionHasPinnedContext ? null : state.roadmapId,
            analysisId: sessionHasPinnedContext ? null : state.analysisId,
            snapshotId: sessionHasPinnedContext ? null : state.snapshotId,
          ),
        );
        final responseMessages = result.messages;
        final latestMessages = state.current?.id == session.id
            ? state.current!.messages
            : session.messages;
        final messages = <ChatMessageModel>[
          ...latestMessages.where(
            (message) =>
                result.userMessage == null || !message.id.startsWith('local-'),
          ),
          if (result.userMessage == null) optimistic,
          ...responseMessages,
        ];
        final uniqueMessages = <ChatMessageModel>[];
        for (final message in messages) {
          final index =
              uniqueMessages.indexWhere((item) => item.id == message.id);
          if (index >= 0) {
            uniqueMessages[index] = message;
          } else {
            uniqueMessages.add(message);
          }
        }
        nextSession = session.copyWith(
          messages: uniqueMessages,
          status: result.status,
          mode: result.mode,
          modeSource: result.modeSource,
          effectiveMode: result.effectiveMode,
          unreadByUser: false,
          lastMessage: uniqueMessages.lastOrNull,
          lastMessageAt: uniqueMessages.lastOrNull?.timestamp,
          repositoryId: result.context?.repositoryId ?? session.repositoryId,
          roadmapId: result.context?.roadmapId ?? session.roadmapId,
          analysisId: result.context?.analysisId ?? session.analysisId,
          snapshotId: result.context?.snapshotId ?? session.snapshotId,
          contextSelectionReason: result.context?.contextSelectionReason ??
              session.contextSelectionReason,
          context: result.context ?? session.context,
        );
      }

      state = state.copyWith(
        current: nextSession,
        sessions: state.sessions.any((s) => s.id == session!.id)
            ? state.sessions
                .map((s) => s.id == session!.id ? nextSession : s)
                .toList()
            : [nextSession, ...state.sessions],
        isSending: false,
      );
    } catch (e) {
      final isClosed = e is ApiException && e.code == 'CHAT_SESSION_CLOSED';
      final failedSession = session.copyWith(
        status: isClosed ? 'closed' : session.status,
      );
      state = state.copyWith(
        current: failedSession,
        sessions: state.sessions
            .map((item) => item.id == session!.id ? failedSession : item)
            .toList(),
        isSending: false,
        error: isClosed
            ? 'Session đã đóng, bạn không thể gửi thêm tin nhắn.'
            : getApiErrorMessage(e),
      );
      rethrow;
    }
  }

  void applyRealtimeMessage(Map<String, dynamic> event) {
    final current = state.current;
    final raw = event['message'];
    if (current == null ||
        event['sessionId']?.toString() != current.id ||
        raw is! Map) {
      return;
    }
    final message = ChatMessageModel.fromJson(Map<String, dynamic>.from(raw));
    if (current.messages.any((item) => item.id == message.id)) return;
    final withoutMatchingOptimistic = current.messages.where((item) {
      return !(item.id.startsWith('local-') &&
          message.effectiveSenderType == 'USER' &&
          item.content == message.content);
    }).toList();
    final updated = current.copyWith(
      messages: [...withoutMatchingOptimistic, message],
      lastMessage: message,
      lastMessageAt: message.timestamp,
    );
    _applyRealtimeSession(updated);
  }

  void applyRealtimeSessionUpdate(Map<String, dynamic> event) {
    final current = state.current;
    final raw = event['session'];
    if (current == null ||
        event['sessionId']?.toString() != current.id ||
        raw is! Map) {
      return;
    }
    final incoming = ChatSessionModel.fromJson(Map<String, dynamic>.from(raw));
    final incomingDate = DateTime.tryParse(incoming.updatedAt ?? '');
    final currentDate = DateTime.tryParse(current.updatedAt ?? '');
    if (incomingDate != null &&
        currentDate != null &&
        incomingDate.isBefore(currentDate)) {
      return;
    }
    _applyRealtimeSession(mergeChatSession(current, incoming));
  }

  void applyRealtimeReadUpdate(Map<String, dynamic> event) {
    final current = state.current;
    final raw = event['session'];
    if (current == null || raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    _applyRealtimeSession(
      current.copyWith(
        unreadByAdmin: map['unreadByAdmin'] == true,
        unreadByUser: map['unreadByUser'] == true,
        updatedAt: map['updatedAt']?.toString(),
      ),
    );
  }

  void setRemoteTyping(bool value) {
    if (state.remoteTyping == value) return;
    state = state.copyWith(remoteTyping: value);
  }

  void _applyRealtimeSession(ChatSessionModel session) {
    state = state.copyWith(
      current: session,
      sessions: state.sessions.any((item) => item.id == session.id)
          ? state.sessions
              .map((item) => item.id == session.id ? session : item)
              .toList()
          : [session, ...state.sessions],
    );
  }
}

final chatProvider =
    NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

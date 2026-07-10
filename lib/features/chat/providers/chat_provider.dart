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
    this.error,
  });

  final List<ChatSessionModel> sessions;
  final ChatSessionModel? current;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    List<ChatSessionModel>? sessions,
    ChatSessionModel? current,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      current: current ?? this.current,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
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

  Future<void> fetchSessions() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessions = AppConfig.demoMode
          ? await DemoService.instance.getChatSessions()
          : await safeRequest(_repository.getChatSessions);

      var current = state.current;
      final synced = current != null ? sessions.where((s) => s.id == current!.id).firstOrNull ?? current : null;
      current = synced ?? (sessions.isNotEmpty ? sessions.first : null);

      if (current != null && current.id.isNotEmpty && !AppConfig.demoMode) {
        try {
          current = await safeRequest(() => _repository.getChatSession(current!.id));
        } catch (_) {}
      } else if (current != null && current.id.isNotEmpty && AppConfig.demoMode) {
        try {
          current = await DemoService.instance.getChatSession(current.id);
        } catch (_) {}
      }

      state = state.copyWith(sessions: sessions, current: current, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
    }
  }

  Future<void> createSession(String title) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sessionTitle = title.trim().isEmpty ? 'Cuộc trò chuyện mới' : title.trim();
      final session = AppConfig.demoMode
          ? await DemoService.instance.createChatSession(sessionTitle)
          : await safeRequest(() => _repository.createChatSession(sessionTitle));
      if (session.id.isEmpty) {
        throw ApiException('Backend không trả session id');
      }
      state = state.copyWith(
        sessions: [session, ...state.sessions.where((s) => s.id != session.id)],
        current: session,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }

  Future<void> selectSession(String id) async {
    final cached = state.sessions.where((s) => s.id == id).firstOrNull;
    if (cached != null) state = state.copyWith(current: cached, clearError: true);
    try {
      final session = AppConfig.demoMode
          ? await DemoService.instance.getChatSession(id)
          : await safeRequest(() => _repository.getChatSession(id));
      state = state.copyWith(
        current: session,
        sessions: state.sessions.map((s) => s.id == id ? session : s).toList(),
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
      state = state.copyWith(error: 'Chat session không có id. Hãy tạo session mới.');
      return;
    }

    final optimistic = ChatMessageModel(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      role: 'user',
      content: content,
      timestamp: DateTime.now().toIso8601String(),
    );
    final updated = session.copyWith(messages: [...session.messages, optimistic]);
    state = state.copyWith(current: updated, isLoading: true, clearError: true);

    try {
      ChatSessionModel nextSession;
      if (AppConfig.demoMode) {
        nextSession = await DemoService.instance.sendChatMessage(session.id, content);
      } else {
        final payload = await safeRequest(() => _repository.sendChatMessage(session!.id, content));
        final record = toRecord(unwrapResponse<dynamic>(payload));
        final hasMessages = record['messages'] is List;
        final responseSession = hasMessages ? normalizeChatSessionDetail(payload) : null;
        final assistant = responseSession == null ? pickAssistantMessage(payload) : null;

        if (responseSession != null) {
          nextSession = mergeChatSession(updated, responseSession);
        } else if (assistant != null) {
          nextSession = updated.copyWith(messages: [...updated.messages, assistant]);
        } else {
          nextSession = updated;
        }

        try {
          final detail = await safeRequest(() => _repository.getChatSession(session!.id));
          if (detail.messages.length >= nextSession.messages.length) {
            nextSession = detail;
          }
        } catch (_) {}
      }

      state = state.copyWith(
        current: nextSession,
        sessions: state.sessions.any((s) => s.id == session!.id)
            ? state.sessions.map((s) => s.id == session!.id ? nextSession : s).toList()
            : [nextSession, ...state.sessions],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: getApiErrorMessage(e));
      rethrow;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);

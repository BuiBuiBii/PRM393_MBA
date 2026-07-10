import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feature_providers.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../widgets/chat_empty_states.dart';
import '../widgets/chat_header.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_sessions_panel.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  static const _prompts = [
    'Dựa trên GitHub của tôi, tôi nên học gì tiếp theo?',
    'Repository nào của tôi nên đưa vào portfolio?',
    'Tôi phù hợp Backend hay Fullstack hơn?',
    'Hãy gợi ý kế hoạch cải thiện commit và documentation.',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatProvider.notifier).fetchSessions();
      ref.read(repositoryProvider.notifier).fetchRepositories();
      ref.read(repositoryProvider.notifier).fetchMyAnalyses();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ref.read(chatProvider.notifier).sendMessage(text);
      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.read(chatProvider).error ?? 'Không gửi được tin nhắn',
          variant: AppSnackVariant.error,
        );
      }
    }
  }

  Future<void> _createSession() async {
    try {
      await ref.read(chatProvider.notifier).createSession('Tư vấn GitHub của tôi');
    } catch (_) {}
  }

  void _openSessions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => ChatSessionsPanel(scrollController: scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final session = chat.current;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    ref.listen(chatProvider.select((s) => s.current?.messages.length), (_, __) => _scrollToBottom());
    if (chat.isLoading) _scrollToBottom();

    return Column(
      children: [
        if (chat.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: BannerMessage(message: chat.error!, isError: true),
          ),
        ChatHeader(
          session: session,
          sessions: chat.sessions,
          onOpenSessions: _openSessions,
          onCreateSession: _createSession,
          onSelectSession: (id) => ref.read(chatProvider.notifier).selectSession(id),
        ),
        Expanded(child: _buildMessages(chat, session)),
        ChatInputBar(
          controller: _controller,
          enabled: !chat.isLoading,
          bottomInset: bottomInset,
          onSend: _send,
        ),
      ],
    );
  }

  Widget _buildMessages(ChatState chat, ChatSessionModel? session) {
    if (session == null) return ChatNoSessionEmpty(onCreateSession: _createSession);
    if (session.messages.isEmpty) {
      return ChatPromptEmpty(prompts: _prompts, onPrompt: (p) => _controller.text = p);
    }

    return ScrollListHints(
      controller: _scrollController,
      child: RefreshIndicator(
        onRefresh: () async {
          if (session.id.isNotEmpty) {
            await ref.read(chatProvider.notifier).selectSession(session.id);
          } else {
            await ref.read(chatProvider.notifier).fetchSessions();
          }
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: session.messages.length + (chat.isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (chat.isLoading && index == session.messages.length) {
              return const ChatTypingIndicator();
            }
            return ChatMessageBubble(message: session.messages[index]);
          },
        ),
      ),
    );
  }
}

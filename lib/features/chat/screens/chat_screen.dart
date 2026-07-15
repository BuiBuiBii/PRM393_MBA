import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/realtime/chat_socket_client.dart';
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
  const ChatScreen({
    super.key,
    this.repositoryId,
    this.roadmapId,
    this.analysisId,
    this.snapshotId,
  });

  final String? repositoryId;
  final String? roadmapId;
  final String? analysisId;
  final String? snapshotId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _outgoingTypingTimer;
  Timer? _remoteTypingTimer;
  ChatSocketBinding? _socketBinding;
  String? _boundSessionId;
  String? _socketIssue;

  static const _repositoryPrompts = [
    'Tại sao tôi hợp role này?',
    'Repo này còn yếu kỹ năng gì?',
    '2 tuần tới nên học gì trước?',
    'Dựa trên repo này, tôi nên ghi gì vào CV?',
    'Tôi nên chuẩn bị phỏng vấn gì?',
  ];
  static const _roadmapPrompts = [
    'Tiến độ roadmap của tôi thế nào?',
    'Task tiếp theo nên làm gì?',
    'Tôi đang bị chậm ở đâu?',
    '2 tuần tới nên ưu tiên task nào?',
  ];
  static const _generalPrompts = [
    'Tôi hợp Backend hay Frontend hơn?',
    'Repo nào nên đưa vào CV?',
    'So sánh các repo đã phân tích của tôi',
    'Tôi nên học gì tiếp theo?',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    Future.microtask(() {
      ref.read(chatProvider.notifier).setContext(
            repositoryId: widget.repositoryId,
            roadmapId: widget.roadmapId,
            analysisId: widget.analysisId,
            snapshotId: widget.snapshotId,
          );
      ref.read(chatProvider.notifier).fetchSessions();
      ref.read(repositoryProvider.notifier).fetchRepositories();
      ref.read(repositoryProvider.notifier).fetchMyAnalyses();
    });
  }

  @override
  void dispose() {
    if (_boundSessionId != null) {
      ref.read(chatSocketClientProvider).sendTyping(_boundSessionId!, false);
    }
    _socketBinding?.dispose();
    _outgoingTypingTimer?.cancel();
    _remoteTypingTimer?.cancel();
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
    if (_boundSessionId != null) {
      ref.read(chatSocketClientProvider).sendTyping(_boundSessionId!, false);
    }
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
    final repositoryState = ref.read(repositoryProvider);
    final analyzedRepositories = repositoryState.repositories.where((repo) {
      return repositoryState.analyses.any(
        (analysis) => analysis.repositoryId == repo.id,
      );
    }).toList();
    final titleController =
        TextEditingController(text: 'Tư vấn GitHub của tôi');
    String? selectedRepositoryId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tạo cuộc trò chuyện'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Tiêu đề'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: selectedRepositoryId,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Ngữ cảnh tư vấn'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Dùng phân tích mới nhất'),
                    ),
                    ...analyzedRepositories.map((repo) {
                      final analysis = repositoryState.analyses.firstWhere(
                        (item) => item.repositoryId == repo.id,
                      );
                      final role =
                          analysis.careerDirection ?? analysis.projectType;
                      return DropdownMenuItem<String?>(
                        value: repo.id,
                        child: Text(
                          '${repo.name} — $role — ${analysis.scores.overall}%',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedRepositoryId = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );
    final title = titleController.text.trim();
    titleController.dispose();
    if (confirmed != true) return;
    try {
      await ref.read(chatProvider.notifier).createSession(
            title.isEmpty ? 'Tư vấn GitHub của tôi' : title,
            repositoryId: selectedRepositoryId,
          );
    } catch (_) {
      if (mounted) {
        AppSnackbar.show(
          context,
          message: ref.read(chatProvider).error ?? 'Không thể tạo chat.',
          variant: AppSnackVariant.error,
        );
      }
    }
  }

  void _openSessions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (_, scrollController) => ChatSessionsPanel(
          scrollController: scrollController,
          onCreateSession: _createSession,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    final session = chat.current;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final socketStatus = ref.watch(chatSocketStatusProvider).asData?.value;

    if (_boundSessionId != session?.id) {
      Future.microtask(() => _bindRealtime(session?.id));
    }

    ref.listen(
      chatProvider.select((state) => state.current?.messages.length),
      (_, __) => _scrollToBottom(),
    );
    ref.listen(chatSocketStatusProvider, (_, next) {
      if (next.asData?.value == ChatSocketStatus.connected &&
          _socketIssue != null &&
          mounted) {
        setState(() => _socketIssue = null);
      }
    });

    return Column(
      children: [
        if (chat.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: BannerMessage(message: chat.error!, isError: true),
          ),
        if (_socketIssue != null ||
            socketStatus == ChatSocketStatus.reconnecting)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: BannerMessage(
              message: _socketIssue ?? 'Đang kết nối lại realtime chat...',
              isError: _socketIssue != null,
            ),
          ),
        ChatHeader(
          session: session,
          sessions: chat.sessions,
          onOpenSessions: _openSessions,
          onCreateSession: _createSession,
          onSelectSession: (id) =>
              ref.read(chatProvider.notifier).selectSession(id),
        ),
        Expanded(child: _buildMessages(chat, session)),
        if (chat.remoteTyping)
          const SizedBox(height: 42, child: ChatTypingIndicator()),
        if (session != null && session.status != 'closed')
          _SuggestedPromptBar(
            prompts: _promptsFor(session),
            onPrompt: (prompt) => _controller.text = prompt,
          ),
        if (session?.effectiveMode == 'MANUAL' ||
            session?.status == 'waiting_admin')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber.withValues(alpha: 0.12),
            child: const Text(
              'Đang chờ admin trả lời',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        if (session?.status == 'closed')
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
            color: Colors.red.withValues(alpha: 0.08),
            child: const Text(
              'Session đã đóng, bạn không thể gửi thêm tin nhắn.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          )
        else
          ChatInputBar(
            controller: _controller,
            enabled: !chat.isLoading && !chat.isSending,
            bottomInset: bottomInset,
            onSend: _send,
          ),
      ],
    );
  }

  Future<void> _bindRealtime(String? sessionId) async {
    if (_boundSessionId == sessionId) return;
    final previous = _boundSessionId;
    _boundSessionId = sessionId;
    if (previous != null) {
      ref.read(chatSocketClientProvider).sendTyping(previous, false);
    }
    _socketBinding?.dispose();
    _socketBinding = null;
    if (_socketIssue != null && mounted) {
      setState(() => _socketIssue = null);
    }
    ref.read(chatProvider.notifier).setRemoteTyping(false);
    if (sessionId == null) return;

    final binding = await ref.read(chatSocketClientProvider).bindSession(
          sessionId: sessionId,
          onMessageCreated: (event) {
            if (mounted) {
              ref.read(chatProvider.notifier).applyRealtimeMessage(event);
            }
          },
          onSessionUpdated: (event) {
            if (mounted) {
              ref.read(chatProvider.notifier).applyRealtimeSessionUpdate(event);
            }
          },
          onTyping: (event) {
            if (!mounted) return;
            final typing = event['isTyping'] == true;
            ref.read(chatProvider.notifier).setRemoteTyping(typing);
            _remoteTypingTimer?.cancel();
            if (typing) {
              _remoteTypingTimer = Timer(const Duration(seconds: 4), () {
                if (mounted) {
                  ref.read(chatProvider.notifier).setRemoteTyping(false);
                }
              });
            }
          },
          onReadUpdated: (event) {
            if (mounted) {
              ref.read(chatProvider.notifier).applyRealtimeReadUpdate(event);
            }
          },
          onError: (issue) {
            if (mounted) {
              setState(() => _socketIssue = '${issue.code}: ${issue.message}');
            }
          },
        );
    if (!mounted || _boundSessionId != sessionId) {
      binding?.dispose();
      return;
    }
    _socketBinding = binding;
  }

  void _onInputChanged() {
    final sessionId = _boundSessionId;
    if (sessionId == null) return;
    final socket = ref.read(chatSocketClientProvider);
    final typing = _controller.text.trim().isNotEmpty;
    socket.sendTyping(sessionId, typing);
    _outgoingTypingTimer?.cancel();
    if (typing) {
      _outgoingTypingTimer = Timer(const Duration(seconds: 2), () {
        socket.sendTyping(sessionId, false);
      });
    }
  }

  Widget _buildMessages(ChatState chat, ChatSessionModel? session) {
    if (session == null) {
      return ChatNoSessionEmpty(onCreateSession: _createSession);
    }
    if (session.messages.isEmpty) {
      return ChatPromptEmpty(
        prompts: _promptsFor(session),
        onPrompt: (prompt) => _controller.text = prompt,
      );
    }

    return ScrollListHints(
      controller: _scrollController,
      child: RefreshIndicator(
        onRefresh: () =>
            ref.read(chatProvider.notifier).selectSession(session.id),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          itemCount: session.messages.length +
              (chat.isSending && session.effectiveMode != 'MANUAL' ? 1 : 0),
          itemBuilder: (context, index) {
            if (chat.isSending &&
                session.effectiveMode != 'MANUAL' &&
                index == session.messages.length) {
              return const ChatTypingIndicator();
            }
            return ChatMessageBubble(message: session.messages[index]);
          },
        ),
      ),
    );
  }

  List<String> _promptsFor(ChatSessionModel session) {
    final hasRoadmap = session.roadmapId?.isNotEmpty == true ||
        session.context?.roadmapId?.isNotEmpty == true;
    if (hasRoadmap) return _roadmapPrompts;
    final hasRepository = session.repositoryId?.isNotEmpty == true ||
        session.context?.repositoryId?.isNotEmpty == true ||
        session.context?.repoName?.isNotEmpty == true;
    return hasRepository ? _repositoryPrompts : _generalPrompts;
  }
}

class _SuggestedPromptBar extends StatelessWidget {
  const _SuggestedPromptBar({required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: prompts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) => ActionChip(
          label: Text(prompts[index]),
          onPressed: () => onPrompt(prompts[index]),
        ),
      ),
    );
  }
}

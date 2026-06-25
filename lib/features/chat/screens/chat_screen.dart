import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';

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
        builder: (_, scrollController) => _SessionsPanel(scrollController: scrollController),
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
        _ChatHeader(
          session: session,
          sessions: chat.sessions,
          onOpenSessions: _openSessions,
          onCreateSession: _createSession,
          onSelectSession: (id) => ref.read(chatProvider.notifier).selectSession(id),
        ),
        Expanded(
          child: session == null
              ? _NoSessionEmpty(onCreateSession: _createSession)
              : session.messages.isEmpty
                  ? _PromptEmpty(
                      prompts: _prompts,
                      onPrompt: (p) => _controller.text = p,
                    )
                  : RefreshIndicator(
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
                            return const _TypingIndicator();
                          }
                          return _MessageBubble(message: session.messages[index]);
                        },
                      ),
                    ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
          decoration: BoxDecoration(
            color: context.appCardColor,
            border: Border(top: BorderSide(color: context.appBorderColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !chat.isLoading,
                  style: TextStyle(color: context.appTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nhập câu hỏi...',
                    filled: true,
                    fillColor: context.isDarkMode ? AppTheme.darkSurface : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.appBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: context.appBorderColor),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: chat.isLoading ? null : _send,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.send_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.session,
    required this.sessions,
    required this.onOpenSessions,
    required this.onCreateSession,
    required this.onSelectSession,
  });

  final ChatSessionModel? session;
  final List<ChatSessionModel> sessions;
  final VoidCallback onOpenSessions;
  final VoidCallback onCreateSession;
  final ValueChanged<String> onSelectSession;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      decoration: BoxDecoration(
        color: context.appCardColor,
        border: Border(bottom: BorderSide(color: context.appBorderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: onOpenSessions, icon: const Icon(Icons.history_rounded), tooltip: 'Lịch sử'),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session?.title ?? 'AI Mentor',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.appSectionTitleStyle,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chat dựa trên repository, phân tích và ngữ cảnh GitHub của bạn.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appLabelStyle.copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onCreateSession,
                icon: const Icon(Icons.add_comment_outlined),
                tooltip: 'Tạo cuộc trò chuyện',
              ),
            ],
          ),
          if (session?.repositoryContext != null) ...[
            const SizedBox(height: 6),
            AppBadge(label: 'Context: ${session!.repositoryContext}', variant: AppBadgeVariant.info),
          ],
          if (sessions.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length > 6 ? 6 : sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = sessions[index];
                  final selected = session?.id == item.id;
                  return InkWell(
                    onTap: () => onSelectSession(item.id),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: context.isDarkMode ? 0.22 : 0.1)
                            : context.appCardColor,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: selected ? AppColors.primary : context.appBorderColor),
                      ),
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: selected ? AppColors.primary : context.appTextSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) const _MentorAvatar(size: 32),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : context.appBubbleAiBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : context.appTextPrimary,
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRelativeTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: isUser ? Colors.white70 : context.appTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MentorAvatar extends StatelessWidget {
  const _MentorAvatar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.primary, AppColors.purple]),
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.5),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const _MentorAvatar(size: 32),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.appBubbleAiBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delayMs: 0),
                SizedBox(width: 4),
                _Dot(delayMs: 150),
                SizedBox(width: 4),
                _Dot(delayMs: 300),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.delayMs});

  final int delayMs;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: context.appTextSecondary, shape: BoxShape.circle),
      ),
    );
  }
}

class _NoSessionEmpty extends StatelessWidget {
  const _NoSessionEmpty({required this.onCreateSession});

  final VoidCallback onCreateSession;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: appScreenPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _MentorAvatar(size: 64),
            const SizedBox(height: 16),
            Text('Hỏi AI Mentor', style: context.appHeadingStyle),
            const SizedBox(height: 8),
            Text(
              'Bạn có thể nhập câu hỏi ngay. Hệ thống sẽ tự tạo cuộc trò chuyện và lưu lại nội dung cho bạn.',
              textAlign: TextAlign.center,
              style: context.appBodyStyle,
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Tạo cuộc trò chuyện', icon: Icons.add, onPressed: onCreateSession),
          ],
        ),
      ),
    );
  }
}

class _PromptEmpty extends StatelessWidget {
  const _PromptEmpty({required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: appScreenPadding(context),
        child: Column(
          children: [
            const _MentorAvatar(size: 64),
            const SizedBox(height: 16),
            Text('Bắt đầu hỏi AI Mentor', style: context.appSectionTitleStyle),
            const SizedBox(height: 16),
            ...prompts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => onPrompt(p),
                  child: Text(p, style: context.appBodyStyle.copyWith(fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsPanel extends ConsumerWidget {
  const _SessionsPanel({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chat = ref.watch(chatProvider);
    final auth = ref.watch(authProvider);
    final repos = ref.watch(repositoryProvider);
    final githubConnected = auth.user?.githubConnected == true;
    final hasAnalyses = repos.analyses.isNotEmpty;

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: context.appBorderColor, borderRadius: BorderRadius.circular(99))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Cuộc trò chuyện', style: context.appSectionTitleStyle),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PrimaryButton(
            label: 'Tạo cuộc trò chuyện',
            icon: Icons.add,
            expand: true,
            onPressed: () async {
              await ref.read(chatProvider.notifier).createSession('Tư vấn GitHub của tôi');
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              children: [
                _ctxRow('GitHub', githubConnected ? 'Đã kết nối' : 'Thiếu', success: githubConnected),
                _ctxRow('Repos', '${repos.repositories.length}'),
                _ctxRow('Phân tích', '${repos.analyses.length}', success: hasAnalyses),
                if (!githubConnected) ...[
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Kết nối GitHub',
                    outlined: true,
                    expand: true,
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/github/connect');
                    },
                  ),
                ] else if (!hasAnalyses) ...[
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Phân tích repo',
                    outlined: true,
                    expand: true,
                    onPressed: () {
                      Navigator.pop(context);
                      context.go('/repositories');
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: chat.sessions.isEmpty
              ? Center(child: Text('Chưa có cuộc trò chuyện.', style: context.appCaptionStyle))
              : ListView.builder(
                  controller: scrollController,
                  itemCount: chat.sessions.length,
                  itemBuilder: (context, index) {
                    final s = chat.sessions[index];
                    return ListTile(
                      selected: chat.current?.id == s.id,
                      selectedTileColor: AppColors.primary.withValues(alpha: context.isDarkMode ? 0.22 : 0.1),
                      title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatRelativeTime(s.createdAt)),
                      onTap: () {
                        ref.read(chatProvider.notifier).selectSession(s.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _ctxRow(String label, String value, {bool success = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            AppBadge(
              label: value,
              variant: success ? AppBadgeVariant.success : AppBadgeVariant.info,
            ),
          ],
        ),
      );
}

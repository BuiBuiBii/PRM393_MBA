import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app_providers.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

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
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await ref.read(chatProvider.notifier).sendMessage(text);
    } catch (_) {}
  }

  void _openSessions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
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

    return Column(
      children: [
        if (chat.error != null) BannerMessage(message: chat.error!, isError: true),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              IconButton(onPressed: _openSessions, icon: const Icon(Icons.history)),
              Expanded(
                child: Text(
                  session?.title ?? 'AI Mentor Chat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: session == null || session.messages.isEmpty
              ? _EmptyChat(
                  prompts: _prompts,
                  onPrompt: (p) => _controller.text = p,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: session.messages.length + (chat.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chat.isLoading && index == session.messages.length) {
                      return const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
                      );
                    }
                    final msg = session!.messages[index];
                    final isUser = msg.role == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg.content, style: TextStyle(color: isUser ? Colors.white : AppColors.slate900)),
                            const SizedBox(height: 4),
                            Text(
                              formatRelativeTime(msg.timestamp),
                              style: TextStyle(fontSize: 11, color: isUser ? Colors.white70 : AppColors.slate500),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomInset),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Nhập câu hỏi...'),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: chat.isLoading ? null : _send, child: const Icon(Icons.send)),
            ],
          ),
        ),
      ],
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

    return Column(
      children: [
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99))),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Cuộc trò chuyện', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                _ctxRow('GitHub', auth.user?.githubConnected == true ? 'Đã kết nối' : 'Thiếu'),
                _ctxRow('Repos', '${repos.repositories.length}'),
                _ctxRow('Phân tích', '${repos.analyses.length}'),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            children: chat.sessions
                .map(
                  (s) => ListTile(
                    selected: chat.current?.id == s.id,
                    title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(formatRelativeTime(s.createdAt)),
                    onTap: () {
                      ref.read(chatProvider.notifier).selectSession(s.id);
                      Navigator.pop(context);
                    },
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _ctxRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), AppBadge(label: value)],
        ),
      );
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.prompts, required this.onPrompt});

  final List<String> prompts;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: appScreenPadding(context),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.purple]),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Bắt đầu hỏi AI mentor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Chọn gợi ý hoặc nhập câu hỏi của bạn', style: TextStyle(color: AppColors.slate500)),
            const SizedBox(height: 16),
            ...prompts.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  onTap: () => onPrompt(p),
                  child: Text(p, style: const TextStyle(fontSize: 13, height: 1.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

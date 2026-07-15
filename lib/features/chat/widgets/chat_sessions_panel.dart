import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../feature_providers.dart';

class ChatSessionsPanel extends ConsumerWidget {
  const ChatSessionsPanel({
    super.key,
    required this.scrollController,
    required this.onCreateSession,
  });

  final ScrollController scrollController;
  final Future<void> Function() onCreateSession;

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
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.appBorderColor,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
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
              Navigator.pop(context);
              await onCreateSession();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppCard(
            child: Column(
              children: [
                _ContextRow(
                  label: 'GitHub',
                  value: githubConnected ? 'Đã kết nối' : 'Thiếu',
                  success: githubConnected,
                ),
                _ContextRow(
                    label: 'Repos', value: '${repos.repositories.length}'),
                _ContextRow(
                  label: 'Phân tích',
                  value: '${repos.analyses.length}',
                  success: hasAnalyses,
                ),
                if (!githubConnected) ...[
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Kết nối GitHub',
                    outlined: true,
                    expand: true,
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/github/connect');
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
              ? Center(
                  child: Text(
                    'Chưa có cuộc trò chuyện.',
                    style: context.appCaptionStyle,
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  itemCount: chat.sessions.length,
                  itemBuilder: (context, index) {
                    final session = chat.sessions[index];
                    final timestamp = session.lastMessageAt ??
                        session.updatedAt ??
                        session.createdAt;
                    return ListTile(
                      selected: chat.current?.id == session.id,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: context.isDarkMode ? 0.22 : 0.1,
                      ),
                      tileColor: session.unreadByUser
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        session.lastMessage?.content.isNotEmpty == true
                            ? session.lastMessage!.content
                            : formatRelativeTime(timestamp),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppBadge(
                            label: _statusLabel(
                                session.status, session.effectiveMode),
                            variant: session.status == 'waiting_admin' ||
                                    session.status == 'closed'
                                ? AppBadgeVariant.warning
                                : AppBadgeVariant.info,
                          ),
                          IconButton(
                            tooltip: 'Xóa cuộc trò chuyện',
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () =>
                                _confirmDelete(context, ref, session.id),
                          ),
                        ],
                      ),
                      onTap: () {
                        ref
                            .read(chatProvider.notifier)
                            .selectSession(session.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _statusLabel(String status, String effectiveMode) {
    return switch (status) {
      'closed' => 'Đã đóng',
      'waiting_admin' => 'Chờ admin',
      'answered' => 'Đã trả lời',
      _ => effectiveMode == 'MANUAL' ? 'Manual' : 'AI Auto',
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text(
          'Cuộc trò chuyện sẽ biến mất khỏi danh sách của bạn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(chatProvider.notifier).deleteSession(sessionId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(chatProvider).error ?? 'Không thể xóa cuộc trò chuyện.',
            ),
          ),
        );
      }
    }
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.label,
    required this.value,
    this.success = false,
  });

  final String label;
  final String value;
  final bool success;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

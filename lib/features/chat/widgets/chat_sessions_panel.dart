import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../feature_providers.dart';

class ChatSessionsPanel extends ConsumerWidget {
  const ChatSessionsPanel({super.key, required this.scrollController});

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
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(color: context.appBorderColor, borderRadius: BorderRadius.circular(99)),
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
                _ContextRow(label: 'GitHub', value: githubConnected ? 'Đã kết nối' : 'Thiếu', success: githubConnected),
                _ContextRow(label: 'Repos', value: '${repos.repositories.length}'),
                _ContextRow(label: 'Phân tích', value: '${repos.analyses.length}', success: hasAnalyses),
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
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.label, required this.value, this.success = false});

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

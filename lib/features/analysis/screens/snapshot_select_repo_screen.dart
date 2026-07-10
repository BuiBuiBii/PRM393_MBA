import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/collapsible_list.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../feature_providers.dart';

class SnapshotSelectRepoScreen extends ConsumerStatefulWidget {
  const SnapshotSelectRepoScreen({super.key});

  @override
  ConsumerState<SnapshotSelectRepoScreen> createState() => _SnapshotSelectRepoScreenState();
}

class _SnapshotSelectRepoScreenState extends ConsumerState<SnapshotSelectRepoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(repositoryProvider.notifier).fetchRepositories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final repos = state.repositories;
    final isLoading = state.isLoading;

    return isLoading && repos.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : repos.isEmpty
            ? _buildEmptyState(context)
            : ScrollListHints(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CollapsibleItemList(
                      items: repos,
                      itemBuilder: (context, repo) => Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.appBorderColor),
                        ),
                        child: InkWell(
                          onTap: () => context.push('/repositories/${repo.id}/snapshots'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.folder_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(repo.name, style: context.appSectionTitleStyle),
                                      if (repo.description != null && repo.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          repo.description!,
                                          style: context.appCaptionStyle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: context.appTextSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 64, color: context.appTextSecondary),
          const SizedBox(height: 16),
          Text(
            'Chưa có repository nào.\nHãy đồng bộ repository của bạn trước.',
            textAlign: TextAlign.center,
            style: context.appCaptionStyle,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Đến trang Repositories',
            onPressed: () => context.go('/repositories'),
          ),
        ],
      ),
    );
  }
}

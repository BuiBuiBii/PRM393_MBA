import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_detail_widgets.dart';
import '../widgets/admin_widgets.dart';

class AdminRepositoryDetailScreen extends ConsumerStatefulWidget {
  const AdminRepositoryDetailScreen({super.key, required this.repositoryId});

  final String repositoryId;

  @override
  ConsumerState<AdminRepositoryDetailScreen> createState() => _AdminRepositoryDetailScreenState();
}

class _AdminRepositoryDetailScreenState extends ConsumerState<AdminRepositoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminRepoDetailProvider.notifier).load(widget.repositoryId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRepoDetailProvider);
    final repo = state.repository;

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: repo != null,
      error: state.error,
      onRetry: () => ref.read(adminRepoDetailProvider.notifier).load(widget.repositoryId),
      child: repo == null
          ? const SizedBox.shrink()
          : ListView(
              padding: appScreenPadding(context),
              children: [
                AdminSectionHeader(
                  title: repo.fullName,
                  subtitle: 'Dữ liệu GitHub đã đồng bộ.',
                  trailing: PrimaryButton(
                    label: 'Làm mới',
                    icon: Icons.refresh,
                    outlined: true,
                    onPressed: () => ref.read(adminRepoDetailProvider.notifier).load(widget.repositoryId),
                  ),
                ),
                const SizedBox(height: 16),
                AdminDetailStatGrid(
                  items: [
                    ('Sao', '${repo.stars ?? 0}'),
                    ('Fork', '${repo.forks ?? 0}'),
                    ('Issue mở', '${repo.openIssues ?? 0}'),
                    ('Dung lượng', '${repo.sizeKb ?? 0} KB'),
                  ],
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              repo.description?.isNotEmpty == true ? repo.description! : 'Repository chưa có mô tả.',
                              style: const TextStyle(color: AppColors.slate600, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppBadge(label: repo.isPrivate ? 'Riêng tư' : 'Công khai', variant: repo.isPrivate ? AppBadgeVariant.warning : AppBadgeVariant.success),
                          if (repo.isFork) const AppBadge(label: 'Fork', variant: AppBadgeVariant.neutral),
                          if (repo.rawBool('archived') == true) const AppBadge(label: 'Archived GitHub', variant: AppBadgeVariant.warning),
                        ],
                      ),
                      const SizedBox(height: 12),
                      adminDetailRow('Người sở hữu', repo.ownerName),
                      if (repo.ownerEmail != null) adminDetailRow('Email', repo.ownerEmail!),
                      adminDetailRow('Ngôn ngữ', repo.language),
                      adminDetailRow('Nhánh chính', repo.defaultBranch ?? 'Chưa rõ'),
                      adminDetailRow('GitHub Repo ID', '${repo.githubRepoId ?? 'Chưa có'}'),
                      adminDetailRow('Đồng bộ gần nhất', formatDate(repo.lastSyncedAt)),
                      adminDetailRow('Cập nhật GitHub', formatDate(repo.updatedAt ?? repo.pushedAt)),
                      adminDetailRow('Tạo bản ghi', formatDate(repo.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Liên kết', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      adminDetailRow('Trang GitHub', repo.htmlUrl ?? 'Chưa có'),
                      adminDetailRow('Clone HTTPS', repo.cloneUrl ?? 'Chưa có'),
                      adminDetailRow('Homepage', repo.homepage ?? 'Chưa có'),
                      if (repo.htmlUrl != null && repo.htmlUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Mở GitHub',
                          icon: Icons.open_in_new,
                          expand: true,
                          onPressed: () => launchUrl(Uri.parse(repo.htmlUrl!), mode: LaunchMode.externalApplication),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Topics', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      if (repo.topics.isEmpty)
                        const Text('Chưa có topic.', style: TextStyle(color: AppColors.slate500))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: repo.topics.map((t) => AppBadge(label: t, variant: AppBadgeVariant.info)).toList(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tính năng GitHub', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      for (final entry in [
                        ('Issues', 'has_issues'),
                        ('Projects', 'has_projects'),
                        ('Wiki', 'has_wiki'),
                        ('Pages', 'has_pages'),
                        ('Discussions', 'has_discussions'),
                        ('Cho phép fork', 'allow_forking'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(child: Text(entry.$1)),
                              AppBadge(
                                label: repo.rawBool(entry.$2) == true ? 'Có' : 'Không',
                                variant: repo.rawBool(entry.$2) == true ? AppBadgeVariant.success : AppBadgeVariant.neutral,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_providers.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

class RepositoryDetailScreen extends ConsumerStatefulWidget {
  const RepositoryDetailScreen({super.key, required this.repoId});

  final String repoId;

  @override
  ConsumerState<RepositoryDetailScreen> createState() => _RepositoryDetailScreenState();
}

class _RepositoryDetailScreenState extends ConsumerState<RepositoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(repositoryProvider.notifier).fetchRepository(widget.repoId));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final repo = state.selected ?? state.repositories.where((r) => r.id == widget.repoId).firstOrNull;

    if (state.isLoading && repo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (repo == null) {
      return EmptyState(
        title: 'Không tìm thấy repository',
        action: TextButton(onPressed: () => context.go('/repositories'), child: const Text('Quay lại')),
      );
    }

    return ListView(
      padding: appScreenPadding(context),
      children: [
        TextButton.icon(
          onPressed: () => context.go('/repositories'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Repositories'),
        ),
        PageHeader(title: repo.name, subtitle: repo.fullName),
        if (repo.description != null) ...[const SizedBox(height: 8), Text(repo.description!)],
        const SizedBox(height: 16),
        AppCard(
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              AppBadge(label: repo.language),
              _meta(Icons.star, '${repo.stars} stars'),
              _meta(Icons.call_split, '${repo.forks} forks'),
              _meta(Icons.schedule, formatRelativeTime(repo.updatedAt)),
              AppBadge(
                label: repo.hasReadme ? 'Có README' : 'Thiếu README',
                variant: repo.hasReadme ? AppBadgeVariant.success : AppBadgeVariant.warning,
              ),
              AppBadge(
                label: repo.analyzed ? 'Đã phân tích' : 'Chưa phân tích',
                variant: repo.analyzed ? AppBadgeVariant.success : AppBadgeVariant.neutral,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Phân tích repository',
          icon: Icons.analytics,
          expand: true,
          loading: state.isAnalyzingRepo(repo.id),
          onPressed: state.isAnalyzing
              ? null
              : () async {
                  try {
                    final result = await ref.read(repositoryProvider.notifier).analyzeRepository(repo.id);
                    if (context.mounted) context.push('/repositories/${result.repositoryId}/analysis');
                  } catch (_) {}
                },
        ),
        const SizedBox(height: 8),
        if (repo.analyzed)
          PrimaryButton(
            label: 'Xem kết quả phân tích',
            outlined: true,
            expand: true,
            onPressed: () => context.push('/repositories/${repo.id}/analysis'),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Mở trên GitHub',
          outlined: true,
          icon: Icons.open_in_new,
          expand: true,
          onPressed: () => launchUrl(Uri.parse(repo.url), mode: LaunchMode.externalApplication),
        ),
      ],
    );
  }

  Widget _meta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.slate500),
          const SizedBox(width: 4),
          Text(text),
        ],
      );
}

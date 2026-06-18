import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_providers.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';

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
    Future.microtask(() {
      final id = widget.repoId;
      ref.read(repositoryProvider.notifier).fetchRepository(id);
      ref.read(repositoryProvider.notifier).fetchPackages(id);
      ref.read(repositoryProvider.notifier).fetchCommits(id);
      ref.read(repositoryProvider.notifier).fetchAiFeedback(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final repo = state.selected ?? state.repositories.where((r) => r.id == widget.repoId).firstOrNull;
    final packages = state.packagesFor(widget.repoId);
    final commits = state.commitsFor(widget.repoId);
    final feedback = state.feedbackFor(widget.repoId);
    final detail = repo;

    return AsyncPageBody(
      isLoading: state.isLoading,
      hasData: detail != null,
      onRetry: () => ref.read(repositoryProvider.notifier).fetchRepository(widget.repoId),
      child: detail == null
          ? const SizedBox.shrink()
          : ListView(
        padding: appScreenPadding(context),
        children: [
          TextButton.icon(
            onPressed: () => context.go('/repositories'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Repositories'),
        ),
        PageHeader(title: detail.name, subtitle: detail.fullName),
        if (detail.description != null) ...[const SizedBox(height: 8), Text(detail.description!)],
        const SizedBox(height: 16),
        AppCard(
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              AppBadge(label: detail.language),
              _meta(Icons.star, '${detail.stars} stars'),
              _meta(Icons.call_split, '${detail.forks} forks'),
              _meta(Icons.schedule, formatRelativeTime(detail.updatedAt)),
              AppBadge(
                label: detail.hasReadme ? 'Có README' : 'Thiếu README',
                variant: detail.hasReadme ? AppBadgeVariant.success : AppBadgeVariant.warning,
              ),
              AppBadge(
                label: detail.analyzed ? 'Đã phân tích' : 'Chưa phân tích',
                variant: detail.analyzed ? AppBadgeVariant.success : AppBadgeVariant.neutral,
              ),
            ],
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: state.error!, isError: true),
        ],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phân tích repository này', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                'Đồng bộ packages, commits, chạy phân tích và lấy AI feedback cho ${detail.fullName}.',
                style: const TextStyle(color: AppColors.slate500, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PrimaryButton(
                    label: detail.analyzed ? 'Phân tích lại' : 'Phân tích ngay',
                    icon: Icons.play_arrow,
                    loading: state.isAnalyzingRepo(detail.id),
                    onPressed: state.isAnalyzing
                        ? null
                        : () async {
                            try {
                              final result = await ref.read(repositoryProvider.notifier).analyzeRepository(detail.id);
                              if (context.mounted) context.push('/repositories/${result.repositoryId}/analysis');
                            } catch (_) {}
                          },
                  ),
                  PrimaryButton(
                    label: 'Tải packages',
                    outlined: true,
                    loading: state.loadingPackagesFor == detail.id,
                    onPressed: () => ref.read(repositoryProvider.notifier).fetchPackages(detail.id, sync: true),
                  ),
                  PrimaryButton(
                    label: 'Tải commits',
                    outlined: true,
                    loading: state.loadingCommitsFor == detail.id,
                    onPressed: () => ref.read(repositoryProvider.notifier).fetchCommits(detail.id, sync: true),
                  ),
                  if (detail.analyzed)
                    PrimaryButton(
                      label: 'Xem phân tích',
                      outlined: true,
                      onPressed: () => context.push('/repositories/${detail.id}/analysis'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Packages / file cấu hình', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (packages.isEmpty)
                const Text('Chưa có packages cached. Bấm Tải packages để đồng bộ.', style: TextStyle(color: AppColors.slate500))
              else
                ...packages.take(8).map(
                      (item) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            previewPayload(item),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lịch sử commit', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              if (commits.isEmpty)
                const Text('Chưa có commits cached. Bấm Tải commits để đồng bộ.', style: TextStyle(color: AppColors.slate500))
              else
                ...commits.take(12).map(
                      (item) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(previewPayload(item), style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiFeedbackPanel(
          feedback: feedback,
          isGenerating: state.isGeneratingFeedback(detail.id),
          onGenerate: () async {
            try {
              await ref.read(repositoryProvider.notifier).generateAiFeedback(detail.id);
            } catch (_) {}
          },
          onRefresh: () => ref.read(repositoryProvider.notifier).fetchAiFeedback(detail.id),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Mở trên GitHub',
          outlined: true,
          icon: Icons.open_in_new,
          expand: true,
          onPressed: () => launchUrl(Uri.parse(detail.url), mode: LaunchMode.externalApplication),
        ),
      ],
      ),
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

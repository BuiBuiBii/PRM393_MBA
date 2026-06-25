import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';

class RepositoriesScreen extends ConsumerStatefulWidget {
  const RepositoriesScreen({super.key});

  @override
  ConsumerState<RepositoriesScreen> createState() => _RepositoriesScreenState();
}

class _RepositoriesScreenState extends ConsumerState<RepositoriesScreen> {
  String _search = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(repositoryProvider.notifier).fetchRepositories();
      ref.read(repositoryProvider.notifier).fetchMyAnalyses();
      ref.read(repositoryProvider.notifier).fetchMyAiFeedbacks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final keyword = _search.toLowerCase();
    final repos = state.repositories.where((r) {
      if (keyword.isEmpty) return true;
      return [r.name, r.fullName, r.description, r.language].any((v) => v?.toLowerCase().contains(keyword) ?? false);
    }).toList();

    return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(
          title: 'Repositories',
          subtitle: 'Đồng bộ repository từ GitHub và chạy phân tích AI.',
          trailing: PrimaryButton(
            label: 'Đồng bộ',
            icon: Icons.refresh,
            loading: state.isLoading,
            expand: isCompactPhone(context),
            onPressed: () => ref.read(repositoryProvider.notifier).fetchRepositories(sync: true),
          ),
        ),
        if (state.error != null) ...[const SizedBox(height: 12), BannerMessage(message: state.error!, isError: true)],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Tìm repository...'),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${repos.length} repository', style: context.appCaptionStyle),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AsyncListBody(
          isLoading: state.isLoading,
          isEmpty: repos.isEmpty,
          error: state.error,
          onRetry: () => ref.read(repositoryProvider.notifier).fetchRepositories(),
          emptyTitle: 'Chưa có repository',
          emptySubtitle: 'Hãy kết nối GitHub và bấm Đồng bộ.',
          child: Column(
            children: [
              ...repos.map((repo) {
            final analysis = state.analyses.where((a) => a.repositoryId == repo.id).firstOrNull;
            final hasAnalysis = analysis != null || repo.analyzed;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push('/repositories/${repo.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(repo.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                if (repo.description != null)
                                  Text(
                                    repo.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.appCaptionStyle,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        AppBadge(label: repo.language),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _chip(Icons.star, '${repo.stars}'),
                        _chip(Icons.call_split, '${repo.forks}'),
                        AppBadge(
                          label: hasAnalysis ? 'Đã phân tích' : 'Chưa phân tích',
                          variant: hasAnalysis ? AppBadgeVariant.success : AppBadgeVariant.neutral,
                        ),
                        Text(formatRelativeTime(repo.updatedAt), style: context.appLabelStyle),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasAnalysis)
                      PrimaryButton(
                        label: 'Xem phân tích',
                        outlined: true,
                        expand: true,
                        onPressed: () => context.push('/repositories/${repo.id}/analysis'),
                      ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: state.isAnalyzingRepo(repo.id) ? 'Đang phân tích...' : (hasAnalysis ? 'Phân tích lại' : 'Phân tích'),
                      icon: hasAnalysis ? Icons.refresh : Icons.play_arrow,
                      loading: state.isAnalyzingRepo(repo.id),
                      expand: true,
                      onPressed: state.isAnalyzing
                          ? null
                          : () async {
                              try {
                                final result = await ref.read(repositoryProvider.notifier).analyzeRepository(repo.id);
                                if (context.mounted) context.push('/repositories/${result.repositoryId}/analysis');
                              } catch (_) {}
                            },
                    ),
                    TextButton.icon(
                      onPressed: () => launchUrl(Uri.parse(repo.url), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Mở GitHub'),
                    ),
                  ],
                ),
              ),
            );
          }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: context.appTextSecondary),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 13, color: context.appTextPrimary)),
        ],
      );
}

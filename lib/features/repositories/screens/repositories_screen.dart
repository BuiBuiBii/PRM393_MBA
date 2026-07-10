import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../feature_providers.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/collapsible_list.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../widgets/repository_card.dart';

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
    Future.microtask(() => ref.read(repositoryProvider.notifier).refreshOverview());
  }

  Future<void> _refresh({bool sync = false}) =>
      ref.read(repositoryProvider.notifier).refreshOverview(syncRepos: sync);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(repositoryProvider);
    final keyword = _search.toLowerCase();
    final repos = state.repositories.where((r) {
      if (keyword.isEmpty) return true;
      return [r.name, r.fullName, r.description, r.language].any((v) => v?.toLowerCase().contains(keyword) ?? false);
    }).toList();
    final listLoading = state.isLoading && state.repositories.isEmpty;

    return ScrollListHints(
      child: RefreshIndicator(
        onRefresh: () => _refresh(sync: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: appScreenPadding(context),
          children: [
            PageHeader(
              title: 'Repositories',
              subtitle: 'Đồng bộ repository từ GitHub và chạy phân tích AI.',
              trailing: PrimaryButton(
                label: 'Đồng bộ',
                icon: Icons.refresh,
                loading: state.isSyncing,
                expand: isCompactPhone(context),
                onPressed: state.isSyncing ? null : () => _refresh(sync: true),
              ),
            ),
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
              isLoading: listLoading,
              isEmpty: repos.isEmpty,
              error: repos.isEmpty ? state.error : null,
              onRetry: () => _refresh(),
              emptyTitle: 'Chưa có repository',
              emptySubtitle: 'Hãy kết nối GitHub và bấm Đồng bộ.',
              child: CollapsibleItemList(
                resetKey: keyword,
                items: repos,
                itemBuilder: (context, repo) {
                  final analysis = state.analyses.where((a) => a.repositoryId == repo.id).firstOrNull;
                  return RepositoryCard(
                    repo: repo,
                    hasAnalysis: analysis != null || repo.analyzed,
                    readinessScore: analysis?.userReadinessScore,
                    overallScore: analysis?.scores.overall,
                    careerPreview: analysis?.careerDirection,
                    isAnalyzing: state.isAnalyzingRepo(repo.id),
                    analyzeDisabled: state.isAnalyzing,
                    onAnalyze: () async {
                      try {
                        final result = await ref.read(repositoryProvider.notifier).analyzeRepository(repo.id);
                        if (context.mounted) context.push('/repositories/${result.repositoryId}/analysis');
                      } catch (_) {}
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

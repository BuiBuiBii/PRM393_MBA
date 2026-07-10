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

    return ScrollListHints(
      child: ListView(
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
            child: CollapsibleItemList(
              resetKey: keyword,
              items: repos,
              itemBuilder: (context, repo) => RepositoryCard(
                repo: repo,
                hasAnalysis: state.analyses.any((a) => a.repositoryId == repo.id) || repo.analyzed,
                isAnalyzing: state.isAnalyzingRepo(repo.id),
                analyzeDisabled: state.isAnalyzing,
                onAnalyze: () async {
                  try {
                    final result = await ref.read(repositoryProvider.notifier).analyzeRepository(repo.id);
                    if (context.mounted) context.push('/repositories/${result.repositoryId}/analysis');
                  } catch (_) {}
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

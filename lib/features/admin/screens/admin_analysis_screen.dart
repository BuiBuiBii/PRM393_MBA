import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminAnalysisScreen extends ConsumerStatefulWidget {
  const AdminAnalysisScreen({super.key});

  @override
  ConsumerState<AdminAnalysisScreen> createState() => _AdminAnalysisScreenState();
}

class _AdminAnalysisScreenState extends ConsumerState<AdminAnalysisScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminAnalysisProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAnalysisProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Kết quả phân tích',
          subtitle: 'Audit phân tích repository trên toàn hệ thống.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm repo, project type...',
          onSubmitted: (q) => ref.read(adminAnalysisProvider.notifier).load(search: q.trim()),
        ),
        const SizedBox(height: 12),
        AsyncListBody(
          isLoading: state.isLoading,
          isEmpty: state.items.isEmpty,
          error: state.items.isEmpty ? state.error : null,
          onRetry: () => ref.read(adminAnalysisProvider.notifier).load(search: _search.text.trim()),
          emptyTitle: 'Không có phân tích',
          emptySubtitle: 'Chưa có snapshot phân tích.',
          child: Column(
            children: [
              ...state.items.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AdminListTileCard(
                    title: a.repoName,
                    subtitle: '${a.ownerName} • ${a.projectType}',
                    badges: [
                      AppBadge(label: a.careerDirection, variant: AppBadgeVariant.info),
                      if (a.overallScore != null)
                        AppBadge(label: 'Score ${a.overallScore}', variant: AppBadgeVariant.success),
                    ],
                    trailing: Icon(Icons.chevron_right, color: context.appTextSecondary),
                    onTap: () => context.push('/admin/analysis/${a.id}'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminAnalysisProvider.notifier).prevPage(),
          onNext: () => ref.read(adminAnalysisProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminAiFeedbackScreen extends ConsumerStatefulWidget {
  const AdminAiFeedbackScreen({super.key});

  @override
  ConsumerState<AdminAiFeedbackScreen> createState() => _AdminAiFeedbackScreenState();
}

class _AdminAiFeedbackScreenState extends ConsumerState<AdminAiFeedbackScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminFeedbackProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminFeedbackProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'AI Feedback',
          subtitle: 'Phản hồi AI đã sinh cho các repository.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm repo, summary...',
          onSubmitted: (q) => ref.read(adminFeedbackProvider.notifier).load(search: q.trim()),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: state.error!, isError: true),
        ],
        const SizedBox(height: 12),
        AsyncListBody(
          isLoading: state.isLoading,
          isEmpty: state.items.isEmpty,
          error: state.error,
          onRetry: () => ref.read(adminFeedbackProvider.notifier).load(search: _search.text.trim()),
          emptyTitle: 'Không có AI feedback',
          emptySubtitle: 'Chưa có bản ghi feedback.',
          child: Column(
            children: [
              ...state.items.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AdminListTileCard(
                    title: f.repoName,
                    subtitle: f.summary.isEmpty ? f.careerDirection : f.summary,
                    badges: [
                      AppBadge(label: f.ownerName, variant: AppBadgeVariant.neutral),
                      AppBadge(label: f.careerDirection, variant: AppBadgeVariant.info),
                    ],
                    trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
                    onTap: () => context.push('/admin/ai-feedback/${f.id}'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminFeedbackProvider.notifier).prevPage(),
          onNext: () => ref.read(adminFeedbackProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

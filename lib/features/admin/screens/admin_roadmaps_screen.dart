import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminRoadmapsScreen extends ConsumerStatefulWidget {
  const AdminRoadmapsScreen({super.key});

  @override
  ConsumerState<AdminRoadmapsScreen> createState() => _AdminRoadmapsScreenState();
}

class _AdminRoadmapsScreenState extends ConsumerState<AdminRoadmapsScreen> {
  final _search = TextEditingController();
  String? _statusFilter;
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminRoadmapsProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload({int? page}) => ref.read(adminRoadmapsProvider.notifier).load(
        page: page ?? ref.read(adminRoadmapsProvider).pagination.page,
        search: _search.text.trim(),
        status: _statusFilter,
      );

  Future<void> _toggleStatus(String id, String currentStatus) async {
    final next = currentStatus == 'active' ? 'archived' : 'active';
    setState(() => _updatingId = id);
    try {
      await safeRequest(() => ref.read(adminApiProvider).updateRoadmapStatus(id, next));
      await _reload();
      if (mounted) {
        AppSnackbar.show(
          context,
          message: next == 'archived' ? 'Đã ẩn roadmap' : 'Đã khôi phục roadmap',
          variant: AppSnackVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(context, message: getApiErrorMessage(e), variant: AppSnackVariant.error);
      }
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRoadmapsProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Quản lý roadmap',
          subtitle: 'Theo dõi lộ trình học và ẩn roadmap không còn phù hợp.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm roadmap, mục tiêu hoặc người tạo...',
          onSubmitted: (q) => ref.read(adminRoadmapsProvider.notifier).load(search: q.trim(), status: _statusFilter),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in [null, 'active', 'archived'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status == null ? 'Tất cả' : (status == 'active' ? 'Hoạt động' : 'Lưu trữ')),
                    selected: _statusFilter == status,
                    onSelected: (_) {
                      setState(() => _statusFilter = status);
                      ref.read(adminRoadmapsProvider.notifier).load(search: _search.text.trim(), status: status);
                    },
                  ),
                ),
            ],
          ),
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
          onRetry: () => _reload(page: 1),
          emptyTitle: 'Không có roadmap',
          emptySubtitle: 'Chưa có lộ trình phù hợp bộ lọc.',
          child: Column(
            children: [
              ...state.items.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AdminListTileCard(
                    title: r.title,
                    subtitle: '${r.ownerName}${r.ownerEmail != null ? ' • ${r.ownerEmail}' : ''}',
                    badges: [
                      adminStatusLabel(r.status),
                      AppBadge(label: '${r.phaseCount} giai đoạn', variant: AppBadgeVariant.info),
                      AppBadge(label: '${r.taskCount} việc học', variant: AppBadgeVariant.neutral),
                      if (r.hourCount > 0) AppBadge(label: '${r.hourCount} giờ', variant: AppBadgeVariant.warning),
                    ],
                    onTap: () => context.push('/admin/roadmaps/${r.id}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_updatingId == r.id)
                          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          IconButton(
                            tooltip: r.status == 'active' ? 'Ẩn roadmap' : 'Khôi phục',
                            onPressed: () => _toggleStatus(r.id, r.status),
                            icon: Icon(
                              r.status == 'active' ? Icons.archive_outlined : Icons.unarchive_outlined,
                              size: 20,
                            ),
                          ),
                        const Icon(Icons.chevron_right, color: AppColors.slate500),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminRoadmapsProvider.notifier).prevPage(),
          onNext: () => ref.read(adminRoadmapsProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

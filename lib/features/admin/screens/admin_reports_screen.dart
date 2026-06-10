import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminReportsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReportsProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Báo cáo & kiểm duyệt',
          subtitle: 'Xử lý báo cáo nội dung từ người dùng.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final status in [null, 'pending', 'reviewing', 'resolved', 'rejected'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(status ?? 'Tất cả'),
                    selected: _statusFilter == status,
                    onSelected: (_) {
                      setState(() => _statusFilter = status);
                      ref.read(adminReportsProvider.notifier).load(status: status);
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
        if (state.isLoading && state.items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (state.items.isEmpty)
          const EmptyState(title: 'Không có báo cáo', subtitle: 'Hàng đợi kiểm duyệt trống.')
        else
          ...state.items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminListTileCard(
                title: r.reason,
                subtitle: '${r.targetType}${r.reporterName != null ? ' • ${r.reporterName}' : ''}',
                badges: [adminStatusLabel(r.status), AppBadge(label: r.targetType, variant: AppBadgeVariant.neutral)],
                trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
                onTap: () => context.push('/admin/reports/${r.id}'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminReportsProvider.notifier).prevPage(),
          onNext: () => ref.read(adminReportsProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

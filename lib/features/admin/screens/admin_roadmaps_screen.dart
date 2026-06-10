import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/network/dio_client.dart';
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
  String? _archivingId;

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

  Future<void> _archive(String id) async {
    setState(() => _archivingId = id);
    try {
      final api = ref.read(adminApiProvider);
      await safeRequest(() => api.updateRoadmapStatus(id, 'archived'));
      await ref.read(adminRoadmapsProvider.notifier).load(
            page: ref.read(adminRoadmapsProvider).pagination.page,
            search: _search.text.trim(),
            status: _statusFilter,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu trữ roadmap')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(getApiErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => _archivingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminRoadmapsProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Roadmaps hệ thống',
          subtitle: 'Xem và kiểm duyệt lộ trình học của người dùng.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm target role...',
          onSubmitted: (q) => ref.read(adminRoadmapsProvider.notifier).load(search: q.trim(), status: _statusFilter),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final status in [null, 'active', 'archived'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(status ?? 'Tất cả'),
                  selected: _statusFilter == status,
                  onSelected: (_) {
                    setState(() => _statusFilter = status);
                    ref.read(adminRoadmapsProvider.notifier).load(search: _search.text.trim(), status: status);
                  },
                ),
              ),
          ],
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: state.error!, isError: true),
        ],
        const SizedBox(height: 12),
        if (state.isLoading && state.items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (state.items.isEmpty)
          const EmptyState(title: 'Không có roadmap', subtitle: 'Chưa có lộ trình nào.')
        else
          ...state.items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminListTileCard(
                title: r.targetRole,
                subtitle: '${r.ownerName}${r.summary != null ? ' • ${r.summary}' : ''}',
                badges: [adminStatusLabel(r.status)],
                trailing: r.status == 'active'
                    ? (_archivingId == r.id
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            tooltip: 'Lưu trữ',
                            onPressed: () => _archive(r.id),
                            icon: const Icon(Icons.archive_outlined, size: 20),
                          ))
                    : null,
              ),
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

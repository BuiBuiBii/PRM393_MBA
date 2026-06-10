import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _search = TextEditingController();
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUsersProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUsersProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Quản lý người dùng',
          subtitle: 'Tìm kiếm, xem vai trò và trạng thái tài khoản.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm email hoặc tên...',
          onSubmitted: (q) => ref.read(adminUsersProvider.notifier).load(search: q.trim(), role: _roleFilter),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final role in [null, 'student', 'mentor', 'counselor', 'admin'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(role ?? 'Tất cả'),
                    selected: _roleFilter == role,
                    onSelected: (_) {
                      setState(() => _roleFilter = role);
                      ref.read(adminUsersProvider.notifier).load(search: _search.text.trim(), role: role);
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
          const EmptyState(title: 'Không có người dùng', subtitle: 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.')
        else
          ...state.items.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminListTileCard(
                title: u.name,
                subtitle: u.email.isEmpty ? 'Không có email' : u.email,
                badges: [adminRoleBadge(u.role), adminStatusLabel(u.status)],
                trailing: const Icon(Icons.chevron_right, color: AppColors.slate500),
                onTap: () => context.push('/admin/users/${u.id}'),
              ),
            ),
          ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminUsersProvider.notifier).prevPage(),
          onNext: () => ref.read(adminUsersProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

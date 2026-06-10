import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminRepositoriesScreen extends ConsumerStatefulWidget {
  const AdminRepositoriesScreen({super.key});

  @override
  ConsumerState<AdminRepositoriesScreen> createState() => _AdminRepositoriesScreenState();
}

class _AdminRepositoriesScreenState extends ConsumerState<AdminRepositoriesScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminReposProvider.notifier).load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminReposProvider);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        const AdminSectionHeader(
          title: 'Repositories hệ thống',
          subtitle: 'Tất cả repository đã đồng bộ từ GitHub.',
        ),
        const SizedBox(height: 12),
        AdminSearchField(
          controller: _search,
          hint: 'Tìm tên repo, ngôn ngữ...',
          onSubmitted: (q) => ref.read(adminReposProvider.notifier).load(search: q.trim()),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: state.error!, isError: true),
        ],
        const SizedBox(height: 12),
        if (state.isLoading && state.items.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (state.items.isEmpty)
          const EmptyState(title: 'Không có repository', subtitle: 'Chưa có dữ liệu đồng bộ.')
        else
          ...state.items.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AdminListTileCard(
                title: r.fullName,
                subtitle: '${r.ownerName} • ${r.language}',
                badges: [
                  if (r.stars != null) AppBadge(label: '★ ${r.stars}', variant: AppBadgeVariant.neutral),
                ],
                trailing: Text(
                  r.updatedAt != null ? formatRelativeTime(r.updatedAt!) : '',
                  style: const TextStyle(color: AppColors.slate500, fontSize: 11),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        AdminPaginationBar(
          pagination: state.pagination,
          onPrev: () => ref.read(adminReposProvider.notifier).prevPage(),
          onNext: () => ref.read(adminReposProvider.notifier).nextPage(),
        ),
      ],
    );
  }
}

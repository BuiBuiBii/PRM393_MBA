import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  const AdminUserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminUserDetailProvider.notifier).load(widget.userId));
  }

  Future<void> _pickStatus(String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in ['active', 'inactive', 'banned'])
              ListTile(
                title: Text(s),
                trailing: s == current ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref.read(adminUserDetailProvider.notifier).updateStatus(widget.userId, picked);
    }
  }

  Future<void> _pickRole(String current) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in ['student', 'mentor', 'counselor', 'admin'])
              ListTile(
                title: Text(r),
                trailing: r == current ? const Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx, r),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref.read(adminUserDetailProvider.notifier).updateRole(widget.userId, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminUserDetailProvider);
    final user = state.user;

    if (state.isLoading && user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (user == null) {
      return Center(child: EmptyState(title: 'Không tải được user', subtitle: state.error));
    }

    return ListView(
      padding: appScreenPadding(context),
      children: [
        AdminSectionHeader(title: user.name, subtitle: user.email.isEmpty ? 'Không có email' : user.email),
        if (state.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: state.error!, isError: true),
        ],
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(spacing: 8, runSpacing: 8, children: [adminRoleBadge(user.role), adminStatusLabel(user.status)]),
              const SizedBox(height: 16),
              _row('Provider', user.provider),
              _row('GitHub', user.githubUsername ?? '—'),
              _row('Tạo lúc', user.createdAt ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thao tác quản trị', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Đổi trạng thái: ${user.status}',
                outlined: true,
                expand: true,
                loading: state.isSaving,
                onPressed: state.isSaving ? null : () => _pickStatus(user.status),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Đổi vai trò: ${user.role}',
                outlined: true,
                expand: true,
                loading: state.isSaving,
                onPressed: state.isSaving ? null : () => _pickRole(user.role),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.slate500))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

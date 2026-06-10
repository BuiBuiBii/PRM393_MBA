import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../providers/admin_provider.dart';
import '../widgets/admin_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminDashboardProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);
    final stats = state.stats;
    final compact = isCompactPhone(context);

    return RefreshIndicator(
      onRefresh: () => ref.read(adminDashboardProvider.notifier).load(),
      child: ListView(
        padding: appScreenPadding(context),
        children: [
          const AdminSectionHeader(
            title: 'Tổng quan hệ thống',
            subtitle: 'Số liệu người dùng, repository, phân tích và báo cáo chờ xử lý.',
          ),
          if (state.error != null) ...[
            const SizedBox(height: 12),
            BannerMessage(message: state.error!, isError: true),
          ],
          const SizedBox(height: 16),
          if (state.isLoading && stats == null)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
          else if (stats != null) ...[
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: compact ? 1.05 : 1.2,
              children: [
                StatCard(
                  label: 'Người dùng',
                  value: '${stats.totalUsers}',
                  icon: Icons.people_outline,
                  iconColor: AppColors.primary,
                  iconBg: const Color(0xFFE0E7FF),
                  subtitle: '${stats.activeUsers} active • ${stats.bannedUsers} banned',
                ),
                StatCard(
                  label: 'Repositories',
                  value: '${stats.repositories}',
                  icon: Icons.folder_copy_outlined,
                  iconColor: AppColors.cyan,
                  iconBg: const Color(0xFFCFFAFE),
                ),
                StatCard(
                  label: 'Phân tích',
                  value: '${stats.analyses}',
                  icon: Icons.analytics_outlined,
                  iconColor: AppColors.emerald,
                  iconBg: const Color(0xFFD1FAE5),
                ),
                StatCard(
                  label: 'AI Feedback',
                  value: '${stats.aiFeedback}',
                  icon: Icons.auto_awesome_outlined,
                  iconColor: AppColors.purple,
                  iconBg: const Color(0xFFEDE9FE),
                ),
                StatCard(
                  label: 'Roadmaps',
                  value: '${stats.activeRoadmaps}',
                  icon: Icons.route_outlined,
                  iconColor: AppColors.primary,
                  iconBg: const Color(0xFFE0E7FF),
                  subtitle: 'đang active',
                ),
                StatCard(
                  label: 'Báo cáo chờ',
                  value: '${stats.pendingReports}',
                  icon: Icons.flag_outlined,
                  iconColor: AppColors.amber,
                  iconBg: const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Quản lý nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            AdminQuickNavCard(
              title: 'Người dùng',
              subtitle: 'Vai trò, trạng thái tài khoản',
              icon: Icons.people_outline,
              color: AppColors.primary,
              count: '${stats.totalUsers}',
              onTap: () => context.go('/admin/users'),
            ),
            const SizedBox(height: 8),
            AdminQuickNavCard(
              title: 'Báo cáo vi phạm',
              subtitle: 'Hàng đợi kiểm duyệt',
              icon: Icons.flag_outlined,
              color: AppColors.amber,
              count: '${stats.pendingReports}',
              onTap: () => context.go('/admin/reports'),
            ),
            const SizedBox(height: 8),
            AdminQuickNavCard(
              title: 'Repositories',
              subtitle: 'Tất cả repo đã đồng bộ',
              icon: Icons.folder_copy_outlined,
              color: AppColors.cyan,
              count: '${stats.repositories}',
              onTap: () => context.go('/admin/repositories'),
            ),
          ],
        ],
      ),
    );
  }
}

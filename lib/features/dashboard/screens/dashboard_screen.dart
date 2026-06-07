import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../../app_providers.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(dashboardProvider.notifier).load();
      ref.read(repositoryProvider.notifier).fetchRepositories();
      ref.read(repositoryProvider.notifier).fetchMyAnalyses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dashboard = ref.watch(dashboardProvider);
    final repoState = ref.watch(repositoryProvider);
    final payload = dashboard.payload ?? {};
    final totalRepos = payload['totalRepositories'] ?? payload['repositoryCount'] ?? repoState.repositories.length;
    final analyzed = payload['analyzedRepositories'] ?? payload['analysisCount'] ?? repoState.analyses.length;
    final githubConnected = payload['githubConnected'] ?? user?.githubConnected ?? false;
    final overall = payload['overallScore'] ?? (repoState.analyses.isNotEmpty ? repoState.analyses.first.scores.overall : 0);

    return ListView(
      padding: appScreenPadding(context),
      children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/profile'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(imageUrl: user?.avatar, name: user?.name, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PageHeader(
                      title: 'Chào mừng, ${user?.name ?? 'bạn'}!',
                      subtitle: 'Chạm để xem hồ sơ • Tổng quan GitHub và phân tích.',
                    ),
                  ),
                    const Icon(Icons.chevron_right, color: AppColors.slate500),
                  ],
                ),
              ),
            ),
          ),
        if (dashboard.error != null) ...[
          const SizedBox(height: 12),
          BannerMessage(message: 'Dashboard API: ${dashboard.error}', isWarning: true),
        ],
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isCompactPhone(context) ? 1.15 : 1.3,
          children: [
            StatCard(label: 'Repositories', value: '$totalRepos', icon: Icons.folder_copy, iconColor: AppColors.primary, iconBg: const Color(0xFFE0E7FF)),
            StatCard(label: 'Đã phân tích', value: '$analyzed', icon: Icons.check_circle_outline, iconColor: AppColors.emerald, iconBg: const Color(0xFFD1FAE5)),
            StatCard(
              label: 'GitHub',
              value: githubConnected ? 'Đã kết nối' : 'Chưa kết nối',
              icon: Icons.code,
              iconColor: AppColors.cyan,
              iconBg: const Color(0xFFCFFAFE),
            ),
            StatCard(label: 'Điểm tổng quan', value: overall == 0 ? '-' : '$overall', icon: Icons.trending_up, iconColor: AppColors.purple, iconBg: const Color(0xFFEDE9FE), valueColor: scoreColor(overall is int ? overall : 0)),
          ],
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Phân tích gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () => context.go('/repositories'), child: const Text('Repositories')),
                ],
              ),
              const SizedBox(height: 8),
              if (repoState.analyses.isEmpty)
                const EmptyState(title: 'Chưa có phân tích', subtitle: 'Hãy đồng bộ repositories và chạy Phân tích.')
              else
                ...repoState.analyses.take(4).map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => context.push('/repositories/${a.repositoryId}/analysis'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.repositoryName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    Text(formatRelativeTime(a.createdAt), style: const TextStyle(color: AppColors.slate500, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Text('${a.scores.overall}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: scoreColor(a.scores.overall))),
                            ],
                          ),
                        ),
                      ),
                    )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Kết nối GitHub',
                outlined: true,
                expand: true,
                leading: const AppSvgIcon(asset: AppAssets.githubIcon, size: 18),
                onPressed: () => context.go('/github/connect'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Đồng bộ / phân tích repository', icon: Icons.folder_copy, outlined: true, expand: true, onPressed: () => context.go('/repositories')),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Hỏi AI Mentor', icon: Icons.chat, outlined: true, expand: true, onPressed: () => context.go('/chat')),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Cài đặt tài khoản', icon: Icons.settings_outlined, outlined: true, expand: true, onPressed: () => context.go('/settings')),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/roadmaps/data/roadmap_mock_data.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = mockHomeAnalysis;
    final compact = isCompactPhone(context);

    return ListView(
      padding: appScreenPadding(context),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBadge(label: 'Phân tích developer bằng AI', variant: AppBadgeVariant.info),
              const SizedBox(height: 12),
              Row(
                children: [
                  const AppBrandLogo(size: 40, withBackground: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'GitAnalyzer AI',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Phân tích repository GitHub, hiểu điểm mạnh kỹ thuật và xây dựng portfolio dễ đánh giá hơn.',
                style: TextStyle(color: AppColors.slate600, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (compact) ...[
                PrimaryButton(
                  label: 'Kết nối GitHub',
                  leading: const AppSvgIcon(asset: AppAssets.githubIcon, size: 18),
                  expand: true,
                  onPressed: () => context.push('/github/connect'),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Xem repositories',
                  outlined: true,
                  expand: true,
                  onPressed: () => context.go('/repositories'),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Kết nối GitHub',
                        leading: const AppSvgIcon(asset: AppAssets.githubIcon, size: 18),
                        expand: true,
                        onPressed: () => context.push('/github/connect'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Xem repositories',
                        outlined: true,
                        expand: true,
                        onPressed: () => context.go('/repositories'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phân tích gần đây', style: TextStyle(color: AppColors.slate500)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      analysis['repositoryName'] as String,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${analysis['overall']}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor(analysis['overall'] as int),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: (analysis['techStack'] as List<String>).map((t) => AppBadge(label: t)).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tính năng chính', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _FeatureTile(
          icon: Icons.bar_chart,
          title: 'Chấm điểm repository',
          subtitle: 'Đánh giá kiến trúc, tài liệu, quy ước và chất lượng commit.',
          onTap: () => context.go('/repositories'),
        ),
        _FeatureTile(
          icon: Icons.route,
          title: 'Lộ trình nghề nghiệp',
          subtitle: 'Biến khoảng trống kỹ năng thành kế hoạch thực tế.',
          onTap: () => context.go('/roadmaps'),
        ),
        _FeatureTile(
          icon: Icons.chat_bubble_outline,
          title: 'Chat AI Mentor',
          subtitle: 'Hỏi tiếp về dự án và nhận bước cải thiện cụ thể.',
          onTap: () => context.go('/chat'),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.icon, required this.title, required this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: AppColors.slate500, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_image_assets.dart';
import '../../../shared/widgets/app_widgets.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({
    super.key,
    required this.userName,
    required this.avatarUrl,
    required this.overallScore,
    required this.githubConnected,
    required this.totalRepos,
    required this.analyzedCount,
    this.onTapProfile,
  });

  final String userName;
  final String? avatarUrl;
  final int overallScore;
  final bool githubConnected;
  final int totalRepos;
  final int analyzedCount;
  final VoidCallback? onTapProfile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [
            AppColors.primary.withValues(alpha: 0.55),
            const Color(0xFF5B21B6).withValues(alpha: 0.45),
          ]
        : const [Color(0xFF4F46E5), Color(0xFF7C3AED)];

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTapProfile,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(imageUrl: avatarUrl, name: userName, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tổng quan GitHub & phân tích kỹ năng',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (overallScore > 0) DashboardScoreRing(score: overallScore),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroPill(
                    icon: Icons.folder_copy_outlined,
                    label: '$totalRepos repo',
                  ),
                  _HeroPill(
                    icon: Icons.analytics_outlined,
                    label: '$analyzedCount đã phân tích',
                  ),
                  _HeroPill(
                    icon: githubConnected ? Icons.link : Icons.link_off,
                    label: githubConnected ? 'GitHub đã kết nối' : 'Chưa kết nối GitHub',
                    highlight: githubConnected,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }
}

class DashboardScoreRing extends StatelessWidget {
  const DashboardScoreRing({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (score.clamp(0, 100)) / 100,
            strokeWidth: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.22),
            color: Colors.white,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                scoreLabel(score),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.appSectionTitleStyle),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: context.appCaptionStyle),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class DashboardCareerCard extends StatelessWidget {
  const DashboardCareerCard({super.key, required this.careerPath});

  final String careerPath;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 88,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primary, AppColors.purple],
              ),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.work_outline, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Định hướng nghề nghiệp', style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          careerPath,
                          style: context.appBodyStyle.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => context.go('/roadmaps'),
                          icon: const Icon(Icons.route_outlined, size: 16),
                          label: const Text('Xem lộ trình'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardSkillsCard extends StatelessWidget {
  const DashboardSkillsCard({
    super.key,
    required this.strongSkills,
    required this.missingSkills,
  });

  final List<String> strongSkills;
  final List<String> missingSkills;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DashboardSectionHeader(
            title: 'Kỹ năng từ phân tích',
            subtitle: 'Dữ liệu từ repository mới nhất trên BE',
          ),
          if (strongSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SkillGroup(
              icon: Icons.check_circle_outline,
              title: 'Điểm mạnh',
              color: AppColors.emerald,
              skills: strongSkills,
              variant: AppBadgeVariant.success,
            ),
          ],
          if (missingSkills.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SkillGroup(
              icon: Icons.flag_outlined,
              title: 'Cần bổ sung',
              color: AppColors.amber,
              skills: missingSkills,
              variant: AppBadgeVariant.warning,
            ),
          ],
        ],
      ),
    );
  }
}

class _SkillGroup extends StatelessWidget {
  const _SkillGroup({
    required this.icon,
    required this.title,
    required this.color,
    required this.skills,
    required this.variant,
  });

  final IconData icon;
  final String title;
  final Color color;
  final List<String> skills;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: skills.take(8).map((s) => AppBadge(label: s, variant: variant)).toList(),
          ),
        ],
      ),
    );
  }
}

class DashboardRecentAnalysesCard extends StatelessWidget {
  const DashboardRecentAnalysesCard({super.key, required this.analyses});

  final List<AnalysisModel> analyses;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            title: 'Phân tích gần đây',
            subtitle: analyses.isEmpty ? null : '${analyses.length} kết quả',
            actionLabel: 'Tất cả',
            onAction: () => context.go('/repositories'),
          ),
          const SizedBox(height: 12),
          if (analyses.isEmpty)
            const EmptyState(
              title: 'Chưa có phân tích',
              subtitle: 'Đồng bộ repository từ GitHub và chạy phân tích để xem điểm số.',
            )
          else
            ...analyses.take(4).map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: DashboardAnalysisTile(analysis: a),
              ),
            ),
        ],
      ),
    );
  }
}

class DashboardAnalysisTile extends StatelessWidget {
  const DashboardAnalysisTile({super.key, required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final score = analysis.scores.overall;
    final color = scoreColor(score);

    return Material(
      color: context.appBubbleAiBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/repositories/${analysis.repositoryId}/analysis'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.repositoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: context.appTextPrimary, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(formatRelativeTime(analysis.createdAt), style: context.appCaptionStyle),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '$score',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, height: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardQuickActionsGrid extends StatelessWidget {
  const DashboardQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionData(
        icon: Icons.folder_copy_outlined,
        label: 'Repositories',
        color: AppColors.primary,
        onTap: () => context.go('/repositories'),
      ),
      _QuickActionData(
        icon: Icons.chat_bubble_outline,
        label: 'AI Mentor',
        color: AppColors.cyan,
        onTap: () => context.go('/chat'),
      ),
      _QuickActionData(
        icon: Icons.route_outlined,
        label: 'Lộ trình',
        color: AppColors.purple,
        onTap: () => context.go('/roadmaps'),
      ),
      _QuickActionData(
        icon: Icons.code,
        label: 'GitHub',
        color: AppColors.slate600,
        svgAsset: AppAssets.githubIcon,
        onTap: () => context.push('/github/connect'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thao tác nhanh', style: context.appSectionTitleStyle),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: actions.map((a) => _QuickActionTile(data: a)).toList(),
        ),
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.svgAsset,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? svgAsset;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.data});

  final _QuickActionData data;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: data.onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: data.svgAsset != null
                ? AppSvgIcon(asset: data.svgAsset!, size: 20, color: data.color)
                : Icon(data.icon, color: data.color, size: 20),
          ),
          const Spacer(),
          Text(
            data.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: context.appTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

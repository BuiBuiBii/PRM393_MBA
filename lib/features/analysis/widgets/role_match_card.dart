import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Card hiển thị kết quả Role Match và nút tạo roadmap.
class RoleMatchCard extends StatelessWidget {
  const RoleMatchCard({
    super.key,
    required this.analysis,
    required this.roleMatch,
    required this.isLoading,
    required this.onCreateRoadmap,
    required this.onRetry,
  });

  final AnalysisModel analysis;
  final RoleMatchModel? roleMatch;
  final bool isLoading;
  final VoidCallback onCreateRoadmap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Hướng nghề nghiệp', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: onCreateRoadmap,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14),
                    SizedBox(width: 4),
                    Text('Tạo Roadmap'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    const SizedBox(height: 8),
                    Text('Đang phân tích role phù hợp...', style: context.appCaptionStyle),
                  ],
                ),
              ),
            )
          else if (roleMatch != null && roleMatch!.topRole.isNotEmpty)
            _RoleMatchContent(roleMatch: roleMatch!)
          else if (analysis.careerDirection != null && analysis.careerDirection!.isNotEmpty)
            Text(analysis.careerDirection!)
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Chưa có dữ liệu Role Match. Nhấn để phân tích lại.',
                    style: context.appCaptionStyle,
                  ),
                ),
                TextButton(onPressed: onRetry, child: const Text('Thử lại')),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoleMatchContent extends StatelessWidget {
  const _RoleMatchContent({required this.roleMatch});

  final RoleMatchModel roleMatch;

  @override
  Widget build(BuildContext context) {
    final top = roleMatch.topMatch;
    final matchScore = top?.matchScore ?? 0.0;
    final matchLevel = top?.matchLevel ?? '';
    final matchLevelLabel = top?.matchLevelLabel ?? matchLevel;
    final levelVariant = _matchLevelVariant(matchLevel);

    final matchedSkills = roleMatch.topMatchedSkills.isNotEmpty ? roleMatch.topMatchedSkills : (top?.matchedSkills ?? []);
    final missingSkills = roleMatch.topMissingSkills.isNotEmpty ? roleMatch.topMissingSkills : (top?.missingSkills ?? []);
    final nextSkills = roleMatch.recommendedNextSkills.isNotEmpty
        ? roleMatch.recommendedNextSkills
        : (top?.recommendedNextSkills ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bạn phù hợp nhất với', style: context.appLabelStyle),
                  const SizedBox(height: 4),
                  Text(
                    roleMatch.topRole,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            if (matchScore > 0)
              AppBadge(
                label: '${matchLevelLabel.isNotEmpty ? matchLevelLabel : 'Match'} · ${matchScore.toStringAsFixed(0)}%',
                variant: levelVariant,
              ),
          ],
        ),
        if (matchedSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          RoleMatchSkillSection(
            icon: Icons.check_circle_outline,
            color: AppColors.emerald,
            title: 'Kỹ năng đã có',
            skills: matchedSkills,
            variant: AppBadgeVariant.success,
          ),
        ],
        if (missingSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          RoleMatchSkillSection(
            icon: Icons.warning_amber_outlined,
            color: AppColors.amber,
            title: 'Kỹ năng còn thiếu',
            skills: missingSkills,
            variant: AppBadgeVariant.warning,
          ),
        ],
        if (nextSkills.isNotEmpty) ...[
          const SizedBox(height: 12),
          RoleMatchSkillSection(
            icon: Icons.trending_up,
            color: AppColors.cyan,
            title: 'Nên học tiếp',
            skills: nextSkills,
            variant: AppBadgeVariant.info,
          ),
        ],
        if (roleMatch.matches.length > 1) ...[
          const SizedBox(height: 12),
          Text('Vai trò khác', style: context.appLabelStyle),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: roleMatch.matches.skip(1).map((item) => OtherRoleChip(item: item)).toList(),
          ),
        ],
      ],
    );
  }

  AppBadgeVariant _matchLevelVariant(String level) {
    switch (level.toLowerCase()) {
      case 'strong':
      case 'high':
        return AppBadgeVariant.success;
      case 'moderate':
      case 'medium':
        return AppBadgeVariant.info;
      case 'low':
      case 'weak':
        return AppBadgeVariant.warning;
      default:
        return AppBadgeVariant.neutral;
    }
  }
}

class RoleMatchSkillSection extends StatelessWidget {
  const RoleMatchSkillSection({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.skills,
    required this.variant,
  });

  final IconData icon;
  final Color color;
  final String title;
  final List<String> skills;
  final AppBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((s) => AppBadge(label: s, variant: variant)).toList(),
        ),
      ],
    );
  }
}

class OtherRoleChip extends StatelessWidget {
  const OtherRoleChip({super.key, required this.item});

  final RoleMatchItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.appBubbleAiBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.role, style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text(
            '${item.matchScore.toStringAsFixed(0)}%',
            style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

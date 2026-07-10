import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Tile chọn 1 role match khi tạo roadmap.
class RoleMatchSuggestionTile extends StatelessWidget {
  const RoleMatchSuggestionTile({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.matchScore,
    required this.matchLevelLabel,
    required this.matchedSkills,
    required this.missingSkills,
    required this.loading,
    required this.onTap,
    this.selected = false,
  });

  final String badge;
  final String title;
  final String subtitle;
  final double matchScore;
  final String matchLevelLabel;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final bool loading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.08) : context.appCardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.appBorderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppBadge(label: badge, variant: AppBadgeVariant.info),
                        const SizedBox(height: 6),
                        Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitle, style: context.appLabelStyle),
                        ],
                      ],
                    ),
                  ),
                  if (loading)
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${matchScore.toStringAsFixed(0)}%',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        if (matchLevelLabel.isNotEmpty)
                          Text(matchLevelLabel, style: context.appCaptionStyle),
                      ],
                    ),
                ],
              ),
              if (matchedSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: matchedSkills
                      .take(4)
                      .map((s) => AppBadge(label: s, variant: AppBadgeVariant.success))
                      .toList(),
                ),
              ],
              if (missingSkills.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: missingSkills
                      .take(3)
                      .map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

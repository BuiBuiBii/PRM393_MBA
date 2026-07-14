import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Readiness, contribution scope and skills returned by Dev2Vec analysis.
class AnalysisReadinessSection extends StatelessWidget {
  const AnalysisReadinessSection({super.key, required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final hasReadiness = analysis.userReadinessScore != null;
    final hasTop = analysis.topSkills.isNotEmpty;
    final hasMissing = analysis.missingSkills.isNotEmpty;
    final hasCareer = analysis.careerDirection != null &&
        analysis.careerDirection!.isNotEmpty;
    final hasBreakdown = analysis.scoreBreakdown.isNotEmpty;
    final scope = analysis.analysisScope;

    if (!hasReadiness &&
        !hasTop &&
        !hasMissing &&
        !hasCareer &&
        !hasBreakdown &&
        scope == null) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sẵn sàng nghề nghiệp', style: context.appSectionTitleStyle),
          if (hasReadiness || analysis.userLevel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (hasReadiness) ...[
                  Text(
                    '${analysis.userReadinessScore}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: scoreColor(analysis.userReadinessScore!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('readiness', style: context.appCaptionStyle),
                ],
                const Spacer(),
                if (analysis.userLevel != null &&
                    analysis.userLevel!.isNotEmpty)
                  AppBadge(
                    label: analysis.userLevel!,
                    variant: AppBadgeVariant.info,
                  ),
              ],
            ),
          ],
          if (hasCareer) ...[
            const SizedBox(height: 10),
            Text(analysis.careerDirection!, style: context.appBodyStyle),
          ],
          if (scope != null) ...[
            const SizedBox(height: 12),
            Text(
              scope.githubUsername.isEmpty
                  ? 'Phạm vi đóng góp cá nhân'
                  : 'Đóng góp của ${scope.githubUsername}',
              style: context.appLabelStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${scope.userCommits}/${scope.totalRepoCommits} commits • '
              '${scope.activeDays} ngày hoạt động',
              style: context.appCaptionStyle,
            ),
          ],
          if (hasTop) ...[
            const SizedBox(height: 12),
            const Text(
              'Kỹ năng nổi bật',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.topSkillDetails.isNotEmpty
                  ? analysis.topSkillDetails
                      .map(
                        (skill) => AppBadge(
                          label: '${skill.displayName} • '
                              '${skill.score.toStringAsFixed(2)} • '
                              '${skill.level}',
                          variant: AppBadgeVariant.success,
                        ),
                      )
                      .toList()
                  : analysis.topSkills
                      .map(
                        (skill) => AppBadge(
                          label: skill,
                          variant: AppBadgeVariant.success,
                        ),
                      )
                      .toList(),
            ),
          ],
          if (hasMissing) ...[
            const SizedBox(height: 12),
            const Text(
              'Kỹ năng còn thiếu',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.amber,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.missingSkills
                  .map(
                    (skill) => AppBadge(
                      label: skill,
                      variant: AppBadgeVariant.warning,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Readiness, level và top/missing skills từ phân tích Dev2Vec.
class AnalysisReadinessSection extends StatelessWidget {
  const AnalysisReadinessSection({super.key, required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final hasReadiness = analysis.userReadinessScore != null;
    final hasTop = analysis.topSkills.isNotEmpty;
    final hasMissing = analysis.missingSkills.isNotEmpty;
    final hasCareer = analysis.careerDirection != null && analysis.careerDirection!.isNotEmpty;
    final hasBreakdown = analysis.scoreBreakdown.isNotEmpty;

    if (!hasReadiness && !hasTop && !hasMissing && !hasCareer && !hasBreakdown) {
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
                if (analysis.userLevel != null && analysis.userLevel!.isNotEmpty)
                  AppBadge(label: analysis.userLevel!, variant: AppBadgeVariant.info),
              ],
            ),
          ],
          if (hasCareer) ...[
            const SizedBox(height: 10),
            Text(analysis.careerDirection!, style: context.appBodyStyle),
          ],
          if (hasTop) ...[
            const SizedBox(height: 12),
            const Text('Kỹ năng nổi bật', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.emerald)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.topSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.success)).toList(),
            ),
          ],
          if (hasMissing) ...[
            const SizedBox(height: 12),
            const Text('Kỹ năng còn thiếu', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.amber)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.missingSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning)).toList(),
            ),
          ],
          if (hasBreakdown) ...[
            const SizedBox(height: 12),
            Text('Thành phần điểm', style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...analysis.scoreBreakdown.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(e.key, style: context.appCaptionStyle)),
                    Text('${e.value}', style: TextStyle(fontWeight: FontWeight.w600, color: scoreColor(e.value))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

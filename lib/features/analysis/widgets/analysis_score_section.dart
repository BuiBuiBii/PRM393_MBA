import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/utils/format_utils.dart';
import '../../../shared/widgets/app_widgets.dart';

/// Điểm tổng quan + chi tiết điểm phân tích.
class AnalysisScoreSection extends StatelessWidget {
  const AnalysisScoreSection({super.key, required this.analysis});

  final AnalysisModel analysis;

  @override
  Widget build(BuildContext context) {
    final scores = [
      ('Kiến trúc', analysis.scores.architecture),
      ('Độ hoàn thiện', analysis.scores.completeness),
      ('Commit', analysis.scores.commitQuality),
      ('Tài liệu', analysis.scores.documentation),
      ('Quy ước', analysis.scores.codeConvention),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: analysis.repositoryName,
          subtitle: '${analysis.projectType} • ${scoreLabel(analysis.scores.overall)}',
        ),
        const SizedBox(height: 8),
        Center(
          child: Column(
            children: [
              Text(
                '${analysis.scores.overall}',
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: scoreColor(analysis.scores.overall),
                ),
              ),
              Text('Điểm tổng quan', style: context.appCaptionStyle),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.techStack.map((t) => AppBadge(label: t, variant: AppBadgeVariant.info)).toList(),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chi tiết điểm', style: context.appSectionTitleStyle),
              const SizedBox(height: 12),
              ...scores.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.$1, style: context.appBodyStyle),
                          Text('${s.$2}', style: TextStyle(fontWeight: FontWeight.bold, color: scoreColor(s.$2))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: s.$2 / 100,
                        backgroundColor: Colors.grey.shade200,
                        color: scoreColor(s.$2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

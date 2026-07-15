import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/roadmap_provider.dart';
import '../utils/roadmap_recommendation.dart';
import '../utils/roadmap_progress_utils.dart';
import '../utils/roadmap_utils.dart';

class RoadmapStatChip extends StatelessWidget {
  const RoadmapStatChip({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.appCardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appBorderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              value,
              style: context.appHeadingStyle.copyWith(fontSize: 22, height: 1),
            ),
          ],
        ),
      ),
    );
  }
}

class RoadmapCompactCard extends StatelessWidget {
  const RoadmapCompactCard({
    super.key,
    required this.roadmap,
    required this.taskCount,
    required this.onTap,
    this.onContinue,
    this.onDelete,
  });

  final RoadmapModel roadmap;
  final int taskCount;
  final VoidCallback onTap;
  final VoidCallback? onContinue;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final percent = roadmapProgressPercent(roadmap);
    final progress = percent.clamp(0, 100) / 100;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
                Text('$percent%',
                    style: context.appLabelStyle
                        .copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roadmap.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.appSectionTitleStyle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    AppBadge(
                        label: roadmap.category, variant: AppBadgeVariant.info),
                    AppBadge(
                      label: formatDifficultyBadge(roadmap.difficulty),
                      variant: difficultyVariant(roadmap.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _meta(context, Icons.schedule,
                        '${roadmap.estimatedWeeks} tuần'),
                    const SizedBox(width: 12),
                    _meta(context, Icons.checklist, '$taskCount nhiệm vụ'),
                    if (roadmap.sourceRepositoriesCount > 0) ...[
                      const SizedBox(width: 12),
                      _meta(context, Icons.folder_outlined,
                          '${roadmap.sourceRepositoriesCount} repo'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onContinue != null)
            IconButton(
              tooltip: 'Tiếp tục',
              onPressed: onContinue,
              icon: const Icon(Icons.play_circle_outline,
                  color: AppColors.primary),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Xóa roadmap',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }

  Widget _meta(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: context.appTextSecondary),
        const SizedBox(width: 4),
        Text(label, style: context.appLabelStyle),
      ],
    );
  }
}

class SkillInsightExpansion extends StatelessWidget {
  const SkillInsightExpansion({super.key, required this.insight});

  final SkillInsightSummary insight;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: const Icon(Icons.insights_outlined,
              color: AppColors.cyan, size: 20),
          title: const Text('Tín hiệu từ phân tích repo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Vuốt xem điểm mạnh & kỹ năng nên bổ sung',
              style: context.appLabelStyle),
          children: [
            if (insight.strongSignals.isNotEmpty) ...[
              const Text('Kỹ năng mạnh',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insight.strongSignals
                    .map((s) =>
                        AppBadge(label: s, variant: AppBadgeVariant.success))
                    .toList(),
              ),
            ],
            if (insight.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Nên bổ sung',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insight.missingSkills
                    .map((s) =>
                        AppBadge(label: s, variant: AppBadgeVariant.warning))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showRoadmapFilterSheet(
  BuildContext context,
  RoadmapFilters filters,
  void Function(RoadmapFilters) onApply, {
  required List<String> categories,
}) {
  var local = filters;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.paddingOf(context).bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Bộ lọc',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: local.category,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: categories
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(formatCategoryFilter(c))))
                      .toList(),
                  onChanged: (v) => setLocal(
                      () => local = local.copyWith(category: v ?? 'All')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: local.difficulty,
                  decoration: const InputDecoration(labelText: 'Cấp độ'),
                  items: const ['All', 'Beginner', 'Intermediate', 'Advanced']
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(formatDifficultyFilter(d))))
                      .toList(),
                  onChanged: (v) => setLocal(
                      () => local = local.copyWith(difficulty: v ?? 'All')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: local.duration,
                  decoration: const InputDecoration(labelText: 'Thời lượng'),
                  items: const ['All', 'Short', 'Medium', 'Long']
                      .map((d) => DropdownMenuItem(
                          value: d, child: Text(formatDurationFilter(d))))
                      .toList(),
                  onChanged: (v) => setLocal(
                      () => local = local.copyWith(duration: v ?? 'All')),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Đặt lại',
                        outlined: true,
                        onPressed: () {
                          onApply(const RoadmapFilters());
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Áp dụng',
                        onPressed: () {
                          onApply(local);
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

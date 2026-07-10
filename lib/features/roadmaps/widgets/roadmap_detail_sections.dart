import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/roadmap_widgets.dart';

class RoadmapDetailInfoCard extends StatelessWidget {
  const RoadmapDetailInfoCard({
    super.key,
    required this.roadmap,
    required this.progress,
    required this.percent,
  });

  final RoadmapModel roadmap;
  final ({int completed, int total, int hoursRemaining}) progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (roadmap.roadmapSource == 'role_matching') ...[
            const AppBadge(label: '⚡ Được cá nhân hóa từ Role Match', variant: AppBadgeVariant.info),
            const SizedBox(height: 8),
          ],
          Text(roadmap.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(label: roadmap.category),
              AppBadge(label: roadmap.difficulty),
              AppBadge(label: '${roadmap.estimatedHours} giờ'),
              AppBadge(label: '${progress.hoursRemaining}h còn lại'),
              AppBadge(label: roadmap.careerOutcome, variant: AppBadgeVariant.info),
              if (roadmap.sourceRepositoriesCount > 0)
                AppBadge(label: '${roadmap.sourceRepositoriesCount} repo', variant: AppBadgeVariant.success),
            ],
          ),
          if (roadmap.roleMatchInfo != null) ...[
            const SizedBox(height: 12),
            RoadmapDev2VecMetaCard(
              roleMatchInfo: roadmap.roleMatchInfo!,
              skillGapSummary: roadmap.skillGapSummary,
              roadmapSource: roadmap.roadmapSource,
            ),
          ],
          if (roadmap.skillGapSummary != null && roadmap.prioritySkills.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.trending_up, size: 14, color: AppColors.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Skill cần học (${roadmap.skillGapSummary!['totalGaps'] ?? roadmap.prioritySkills.length} gap)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.cyan),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: roadmap.prioritySkills
                            .take(5)
                            .map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          RoadmapProgressBar(
            percent: percent,
            caption: '$percent% hoàn thành • ${progress.completed}/${progress.total} node',
          ),
        ],
      ),
    );
  }
}

class RoadmapDetailTabBar extends StatelessWidget {
  const RoadmapDetailTabBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appBubbleAiBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _TabButton(index: 0, label: 'Lộ trình', icon: Icons.alt_route, selected: selectedTab, onTap: onTabSelected),
          _TabButton(index: 1, label: 'Mục tiêu', icon: Icons.track_changes, selected: selectedTab, onTap: onTabSelected),
          _TabButton(index: 2, label: 'Bổ trợ', icon: Icons.extension, selected: selectedTab, onTap: onTabSelected),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.index,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final IconData icon;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.appCardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? AppColors.primary : context.appTextSecondary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? context.appTextPrimary : context.appTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoadmapObjectivesTab extends StatelessWidget {
  const RoadmapObjectivesTab({super.key, required this.roadmap});

  final RoadmapModel roadmap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Mục tiêu học tập', icon: Icons.flag, color: AppColors.primary),
        const SizedBox(height: 8),
        if (roadmap.objectives.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Chưa có thông tin mục tiêu học tập.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roadmap.objectives
                  .map(
                    (obj) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(obj, style: context.appBodyStyle)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Kỹ năng hiện có', icon: Icons.star_border, color: AppColors.emerald),
        const SizedBox(height: 8),
        if (roadmap.requiredSkills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Chưa phân tích được kỹ năng hiện có.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roadmap.requiredSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.success)).toList(),
            ),
          ),
        const SizedBox(height: 16),
        _SectionHeader(title: 'Kỹ năng cần bổ sung', icon: Icons.warning_amber_rounded, color: AppColors.amber),
        const SizedBox(height: 8),
        if (roadmap.missingSkills.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Không phát hiện kỹ năng thiếu hụt nào.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roadmap.missingSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning)).toList(),
            ),
          ),
      ],
    );
  }
}

class RoadmapSupportTab extends StatelessWidget {
  const RoadmapSupportTab({super.key, required this.roadmap});

  final RoadmapModel roadmap;

  @override
  Widget build(BuildContext context) {
    if (roadmap.supportingPaths.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text('Không có hướng đi bổ trợ nào.', style: TextStyle(fontStyle: FontStyle.italic)),
        ),
      );
    }

    return Column(
      children: roadmap.supportingPaths
          .map(
            (path) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore, color: AppColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(path.title, style: context.appSectionTitleStyle.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(path.reason, style: context.appBodyStyle),
                    const SizedBox(height: 12),
                    if (path.skills.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: path.skills.map((s) => AppBadge(label: s)).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text('Nhiệm vụ gợi ý:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 6),
                    ...path.suggestedTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan)),
                            Expanded(child: Text(task, style: context.appBodyStyle.copyWith(fontSize: 13))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, required this.color});

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: context.appSectionTitleStyle),
      ],
    );
  }
}

/// Metadata Dev2Vec trên roadmap detail.
class RoadmapDev2VecMetaCard extends StatelessWidget {
  const RoadmapDev2VecMetaCard({
    super.key,
    required this.roleMatchInfo,
    this.skillGapSummary,
    this.roadmapSource,
  });

  final Map<String, dynamic> roleMatchInfo;
  final Map<String, dynamic>? skillGapSummary;
  final String? roadmapSource;

  @override
  Widget build(BuildContext context) {
    final roleName = roleMatchInfo['roleName'] ?? roleMatchInfo['matchedRole'] ?? '';
    final matchScore = roleMatchInfo['matchScore'];
    final matchLevel = roleMatchInfo['matchLevelLabel'] ?? roleMatchInfo['matchLevel'] ?? '';
    final scoringMethod = roleMatchInfo['scoringMethod']?.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cá nhân hóa theo Dev2Vec', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(
            '$roleName  •  ${matchScore?.toString() ?? '-'}%  •  $matchLevel',
            style: context.appBodyStyle,
          ),
          if (scoringMethod != null && scoringMethod.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Phương pháp: $scoringMethod', style: context.appCaptionStyle),
          ],
          if (roadmapSource != null && roadmapSource!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Nguồn roadmap: $roadmapSource', style: context.appCaptionStyle),
          ],
          if (skillGapSummary != null && skillGapSummary!['totalGaps'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Skill gaps: ${skillGapSummary!['totalGaps']}',
              style: context.appLabelStyle,
            ),
          ],
        ],
      ),
    );
  }
}

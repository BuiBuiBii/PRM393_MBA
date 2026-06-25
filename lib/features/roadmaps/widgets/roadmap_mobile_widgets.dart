import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_feedback.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../app_providers.dart';
import '../data/roadmap_mock_data.dart';
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
  });

  final RoadmapModel roadmap;
  final int taskCount;
  final VoidCallback onTap;
  final VoidCallback? onContinue;

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
                Text('$percent%', style: context.appLabelStyle.copyWith(fontWeight: FontWeight.w700)),
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
                    AppBadge(label: roadmap.category, variant: AppBadgeVariant.info),
                    AppBadge(
                      label: formatDifficultyBadge(roadmap.difficulty),
                      variant: difficultyVariant(roadmap.difficulty),
                    ),
                    if (roadmap.isArchived)
                      const AppBadge(label: 'Lưu trữ', variant: AppBadgeVariant.warning),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _meta(context, Icons.schedule, '${roadmap.estimatedWeeks} tuần'),
                    const SizedBox(width: 12),
                    _meta(context, Icons.checklist, '$taskCount nhiệm vụ'),
                    if (roadmap.sourceRepositoriesCount > 0) ...[
                      const SizedBox(width: 12),
                      _meta(context, Icons.folder_outlined, '${roadmap.sourceRepositoriesCount} repo'),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (onContinue != null && !roadmap.isArchived)
            IconButton(
              tooltip: 'Tiếp tục',
              onPressed: onContinue,
              icon: const Icon(Icons.play_circle_outline, color: AppColors.primary),
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
          leading: const Icon(Icons.insights_outlined, color: AppColors.cyan, size: 20),
          title: const Text('Tín hiệu từ phân tích repo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text('Vuốt xem điểm mạnh & kỹ năng nên bổ sung', style: context.appLabelStyle),
          children: [
            if (insight.strongSignals.isNotEmpty) ...[
              const Text('Kỹ năng mạnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.emerald)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insight.strongSignals.map((s) => AppBadge(label: s, variant: AppBadgeVariant.success)).toList(),
              ),
            ],
            if (insight.missingSkills.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Nên bổ sung', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.amber)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: insight.missingSkills.map((s) => AppBadge(label: s, variant: AppBadgeVariant.warning)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

Future<void> showRoadmapFilterSheet(BuildContext context, RoadmapFilters filters, void Function(RoadmapFilters) onApply) {
  var local = filters;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Bộ lọc', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: local.category,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: roadmapCategories.map((c) => DropdownMenuItem(value: c, child: Text(formatCategoryFilter(c)))).toList(),
                  onChanged: (v) => setLocal(() => local = local.copyWith(category: v ?? 'All')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: local.difficulty,
                  decoration: const InputDecoration(labelText: 'Cấp độ'),
                  items: const ['All', 'Beginner', 'Intermediate', 'Advanced']
                      .map((d) => DropdownMenuItem(value: d, child: Text(formatDifficultyFilter(d))))
                      .toList(),
                  onChanged: (v) => setLocal(() => local = local.copyWith(difficulty: v ?? 'All')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: local.duration,
                  decoration: const InputDecoration(labelText: 'Thời lượng'),
                  items: const ['All', 'Short', 'Medium', 'Long']
                      .map((d) => DropdownMenuItem(value: d, child: Text(formatDurationFilter(d))))
                      .toList(),
                  onChanged: (v) => setLocal(() => local = local.copyWith(duration: v ?? 'All')),
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

Future<void> showCreateRoadmapSheet(
  BuildContext context, {
  required List<AnalysisModel> analyses,
  RoleMatchModel? roleMatch,
  required String selectedRole,
  required bool isGenerating,
  required Future<void> Function(String role) onGenerate,
}) {
  final primary = recommendRoadmapRole(analyses);
  final secondary = recommendJobReadinessRoadmaps(analyses);

  final dropdownRoles = <String>[];
  if (roleMatch != null && roleMatch.matches.isNotEmpty) {
    for (final match in roleMatch.matches) {
      if (!dropdownRoles.contains(match.role)) dropdownRoles.add(match.role);
    }
  }
  for (final r in AppConfig.targetRoles) {
    if (!dropdownRoles.contains(r)) dropdownRoles.add(r);
  }

  var role = dropdownRoles.contains(selectedRole) ? selectedRole : dropdownRoles.first;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.paddingOf(context).bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Tạo roadmap mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn vai trò hoặc dùng đề xuất AI từ repository đã phân tích.',
                    style: context.appCaptionStyle,
                  ),
                  const SizedBox(height: 16),
                  
                  if (roleMatch != null && roleMatch.matches.isNotEmpty) ...[
                    const Text('Gợi ý từ Role Match', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    for (var i = 0; i < roleMatch.matches.length; i++) ...[
                      () {
                        final match = roleMatch.matches[i];
                        final details = <String>[
                          'Điểm phù hợp: ${match.matchScore.toStringAsFixed(1)}% ',
                          if (match.category.isNotEmpty) 'Danh mục: ${match.category}',
                          if (match.description.isNotEmpty) match.description,
                        ].join('\n');

                        return _SuggestionTile(
                          badge: i == 0 ? 'Role phù hợp nhất' : 'Role phù hợp',
                          title: match.role,
                          subtitle: details,
                          loading: isGenerating && role == match.role,
                          onTap: isGenerating
                              ? null
                              : () async {
                                  setLocal(() => role = match.role);
                                  await onGenerate(match.role);
                                  if (context.mounted) Navigator.pop(context);
                                },
                        );
                      }(),
                      const SizedBox(height: 10),
                    ],
                  ] else ...[
                    if (primary != null) ...[
                      _SuggestionTile(
                        badge: 'Đề xuất chính',
                        title: primary.role,
                        subtitle: primary.reason,
                        loading: isGenerating && role == primary.role,
                        onTap: isGenerating
                            ? null
                            : () async {
                                setLocal(() => role = primary.role);
                                await onGenerate(primary.role);
                                if (context.mounted) Navigator.pop(context);
                              },
                      ),
                      const SizedBox(height: 10),
                    ],
                    for (final item in secondary) ...[
                      _SuggestionTile(
                        badge: 'Phụ trợ xin việc',
                        title: item.title,
                        subtitle: '${item.role} · ${item.reason}',
                        loading: isGenerating && role == item.role,
                        onTap: isGenerating
                            ? null
                            : () async {
                                setLocal(() => role = item.role);
                                await onGenerate(item.role);
                                if (context.mounted) Navigator.pop(context);
                              },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                  const Divider(height: 24),
                  DropdownButtonFormField<String>(
                    value: role,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Vai trò mục tiêu'),
                    items: dropdownRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: isGenerating ? null : (v) => setLocal(() => role = v ?? role),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Tạo lộ trình',
                    icon: Icons.auto_awesome,
                    expand: true,
                    loading: isGenerating,
                    onPressed: isGenerating
                        ? null
                        : () async {
                            await onGenerate(role);
                            if (context.mounted) Navigator.pop(context);
                          },
                  ),
                  if (analyses.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có phân tích repository — đề xuất AI sẽ hạn chế. Hãy phân tích repo trước để gợi ý chính xác hơn.',
                      style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final String badge;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appBubbleAiBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppBadge(label: badge, variant: AppBadgeVariant.info),
                    const SizedBox(height: 6),
                    Text(title, style: context.appSectionTitleStyle.copyWith(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: context.appLabelStyle),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(Icons.chevron_right, color: context.appTextSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> generateAndOpenRoadmap(
  BuildContext context,
  WidgetRef ref,
  String role, {
  String? repoId,
}) async {
  final notifier = ref.read(roadmapProvider.notifier);
  notifier.setTargetRole(role);
  try {
    if (ref.read(roadmapProvider).statusFilter != 'active') {
      await notifier.setStatusFilter('active');
    }
    final roadmap = await notifier.generateAI(
      targetRole: role,
      repoId: repoId,
    );
    if (!context.mounted || roadmap == null) return;
    AppSnackbar.show(context, message: 'Đã tạo roadmap cho $role', variant: AppSnackVariant.success);
    context.push('/roadmaps/${roadmap.slug.isNotEmpty ? roadmap.slug : roadmap.id}');
  } catch (e) {
    if (context.mounted) {
      AppSnackbar.show(
        context,
        message: ref.read(roadmapProvider).error ?? 'Không thể tạo roadmap',
        variant: AppSnackVariant.error,
      );
    }
  }
}

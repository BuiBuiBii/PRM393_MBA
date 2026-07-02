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
  RoleMatchResponse? roleMatch,
  List<RoleCatalogItem> roleCatalog = const [],
  String? selectedRole,
  bool isGenerating = false,
  String initialSourceMode = 'all_analyzed_repos',
  String? currentRepoId,
  required Future<void> Function(CreateRoadmapRequest request) onGenerate,
}) {
  final primary = recommendRoadmapRole(analyses);
  final secondary = recommendJobReadinessRoadmaps(analyses);
  final roleOptions = <_RoleOption>[];

  void addRole(_RoleOption option) {
    if (option.roleName.trim().isEmpty) return;
    final optionId = (option.roleId ?? '').toLowerCase();
    final optionName = option.roleName.trim().toLowerCase();
    final exists = roleOptions.any((item) {
      final itemId = (item.roleId ?? '').toLowerCase();
      final itemName = item.roleName.trim().toLowerCase();
      return (optionId.isNotEmpty && itemId == optionId) || itemName == optionName;
    });
    if (!exists) roleOptions.add(option);
  }

  for (final role in roleCatalog) {
    addRole(_RoleOption(
      roleId: role.roleId.isNotEmpty ? role.roleId : null,
      roleName: role.roleName,
    ));
  }
  if (roleOptions.isEmpty) {
    for (final role in AppConfig.targetRoles) {
      addRole(_RoleOption(roleName: role));
    }
  }

  final initialMatch = roleMatch?.matches.isNotEmpty == true ? roleMatch!.matches.first : null;
  final initialRoleName = selectedRole ??
      initialMatch?.displayRoleName ??
      primary?.role ??
      (roleOptions.isNotEmpty ? roleOptions.first.roleName : 'Backend Developer');
  _RoleOption? selectedOption = _findRoleOption(
    roleOptions,
    roleId: initialMatch?.roleId,
    roleName: initialRoleName,
  );
  var selectedRoleId = selectedOption?.roleId ?? initialMatch?.roleId;
  var selectedRoleName = selectedOption?.roleName ?? initialRoleName;
  var sourceMode = initialSourceMode;
  var selectedRepoIds = <String>{
    if (sourceMode == 'single_repo' && currentRepoId != null && currentRepoId.isNotEmpty) currentRepoId,
  };
  var level = (analyses.isNotEmpty ? analyses.first.summary?.userLevel : null) ?? 'beginner';
  var durationWeeks = 6;
  var language = 'vi';
  var useRoleMatching = true;
  var forceRegenerate = false;

  String repoIdOf(AnalysisModel analysis) =>
      analysis.repositoryId.isNotEmpty ? analysis.repositoryId : (analysis.repository?.repositoryId ?? analysis.id);

  CreateRoadmapRequest buildRequest() => CreateRoadmapRequest(
        targetRole: selectedRoleName.trim(),
        roleId: selectedRoleId,
        level: level,
        durationWeeks: durationWeeks,
        language: language,
        useRoleMatching: useRoleMatching,
        forceRegenerate: forceRegenerate,
        sourceMode: sourceMode,
        repoId: sourceMode == 'single_repo' && selectedRepoIds.isNotEmpty ? selectedRepoIds.first : null,
        repoIds: sourceMode == 'selected_repos' ? selectedRepoIds.toList() : const [],
      );

  Future<void> submit() async {
    final request = buildRequest();
    if (request.targetRole.isEmpty) return;
    if (request.sourceMode == 'single_repo' && (request.repoId ?? '').isEmpty) return;
    if (request.sourceMode == 'selected_repos' && request.repoIds.isEmpty) return;
    await onGenerate(request);
    if (context.mounted) Navigator.pop(context);
  }

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
                  const Text('Tao roadmap moi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Chon role, nguon phan tich va cau hinh tao roadmap.', style: context.appCaptionStyle),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedOption?.key,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Vai tro muc tieu'),
                    items: roleOptions
                        .map((role) => DropdownMenuItem(value: role.key, child: Text(role.roleName)))
                        .toList(),
                    onChanged: isGenerating
                        ? null
                        : (value) => setLocal(() {
                              selectedOption = _firstWhereOrNull(roleOptions, (item) => item.key == value);
                              selectedRoleId = selectedOption?.roleId;
                              selectedRoleName = selectedOption?.roleName ?? selectedRoleName;
                            }),
                  ),
                  if (selectedOption == null && selectedRoleName.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    AppBadge(label: 'Da chon: $selectedRoleName', variant: AppBadgeVariant.info),
                  ],
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'single_repo', label: Text('Repo hien tai'), icon: Icon(Icons.folder_outlined, size: 16)),
                      ButtonSegment(value: 'all_analyzed_repos', label: Text('Tat ca'), icon: Icon(Icons.all_inbox, size: 16)),
                      ButtonSegment(value: 'selected_repos', label: Text('Chon repo'), icon: Icon(Icons.checklist, size: 16)),
                    ],
                    selected: {sourceMode},
                    onSelectionChanged: isGenerating
                        ? null
                        : (value) => setLocal(() {
                              sourceMode = value.first;
                              if (sourceMode == 'single_repo') {
                                selectedRepoIds = {
                                  if (currentRepoId != null && currentRepoId.isNotEmpty)
                                    currentRepoId
                                  else if (analyses.isNotEmpty)
                                    repoIdOf(analyses.first),
                                };
                              } else if (sourceMode == 'all_analyzed_repos') {
                                selectedRepoIds = {};
                              }
                            }),
                  ),
                  if (sourceMode == 'selected_repos') ...[
                    const SizedBox(height: 8),
                    ...analyses.map((analysis) {
                      final repoId = repoIdOf(analysis);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: selectedRepoIds.contains(repoId),
                        title: Text(analysis.repositoryName),
                        subtitle: Text(repoId),
                        onChanged: isGenerating
                            ? null
                            : (checked) => setLocal(() {
                                  if (checked == true) {
                                    selectedRepoIds = {...selectedRepoIds, repoId};
                                  } else {
                                    selectedRepoIds = selectedRepoIds.where((id) => id != repoId).toSet();
                                  }
                                }),
                      );
                    }),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: level,
                          decoration: const InputDecoration(labelText: 'Cap do'),
                          items: const ['beginner', 'intermediate', 'advanced']
                              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                              .toList(),
                          onChanged: isGenerating ? null : (value) => setLocal(() => level = value ?? level),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: durationWeeks,
                          decoration: const InputDecoration(labelText: 'Tuan'),
                          items: const [4, 6, 8, 12]
                              .map((item) => DropdownMenuItem(value: item, child: Text('$item')))
                              .toList(),
                          onChanged: isGenerating ? null : (value) => setLocal(() => durationWeeks = value ?? durationWeeks),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: language,
                          decoration: const InputDecoration(labelText: 'Ngon ngu'),
                          items: const ['vi', 'en'].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                          onChanged: isGenerating ? null : (value) => setLocal(() => language = value ?? language),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tao lai'),
                          value: forceRegenerate,
                          onChanged: isGenerating ? null : (value) => setLocal(() => forceRegenerate = value),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dung role matching'),
                    value: useRoleMatching,
                    onChanged: isGenerating ? null : (value) => setLocal(() => useRoleMatching = value ?? useRoleMatching),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Tao lo trinh',
                    icon: Icons.auto_awesome,
                    expand: true,
                    loading: isGenerating,
                    onPressed: isGenerating ? null : submit,
                  ),
                  const SizedBox(height: 16),
                  if (roleMatch != null && roleMatch.matches.isNotEmpty) ...[
                    const Text('Goi y role', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    const SizedBox(height: 8),
                    ...roleMatch.matches.take(3).map((match) {
                      final details = <String>[
                        'Diem phu hop: ${match.matchScore.toStringAsFixed(1)}%',
                        if ((match.matchLevelLabel).isNotEmpty) match.matchLevelLabel,
                        if (match.recommendedNextSkills.isNotEmpty) 'Nen hoc: ${match.recommendedNextSkills.take(3).join(', ')}',
                      ].join('\n');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionTile(
                          badge: match == roleMatch.matches.first ? 'De xuat chinh' : 'Ho tro xin viec',
                          title: match.displayRoleName,
                          subtitle: details,
                          loading: false,
                          onTap: isGenerating
                              ? null
                              : () {
                                  setLocal(() {
                                    selectedOption = _findRoleOption(
                                      roleOptions,
                                      roleId: match.roleId,
                                      roleName: match.roleName ?? match.role,
                                    );
                                    selectedRoleId = match.roleId ?? selectedOption?.roleId;
                                    selectedRoleName = match.roleName ?? match.role;
                                  });
                                },
                        ),
                      );
                    }),
                  ] else ...[
                    if (primary != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SuggestionTile(
                          badge: 'De xuat chinh',
                          title: primary.role,
                          subtitle: primary.reason,
                          loading: false,
                          onTap: isGenerating
                              ? null
                              : () {
                                  setLocal(() {
                                    selectedOption = _findRoleOption(roleOptions, roleName: primary.role);
                                    selectedRoleId = selectedOption?.roleId;
                                    selectedRoleName = primary.role;
                                  });
                                },
                        ),
                      ),
                    ...secondary.take(3).map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SuggestionTile(
                            badge: 'Ho tro xin viec',
                            title: item.title,
                            subtitle: '${item.role} - ${item.reason}',
                            loading: false,
                            onTap: isGenerating
                                ? null
                                : () {
                                    setLocal(() {
                                      selectedOption = _findRoleOption(roleOptions, roleName: item.role);
                                      selectedRoleId = selectedOption?.roleId;
                                      selectedRoleName = item.role;
                                    });
                                  },
                          ),
                        )),
                  ],
                  if (analyses.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Chua co phan tich repository. Hay phan tich repo de goi y chinh xac hon.',
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

class CreateRoadmapRequest {
  const CreateRoadmapRequest({
    required this.targetRole,
    this.roleId,
    required this.level,
    required this.durationWeeks,
    required this.language,
    required this.useRoleMatching,
    required this.forceRegenerate,
    required this.sourceMode,
    this.repoId,
    this.repoIds = const [],
  });

  final String targetRole;
  final String? roleId;
  final String level;
  final int durationWeeks;
  final String language;
  final bool useRoleMatching;
  final bool forceRegenerate;
  final String sourceMode;
  final String? repoId;
  final List<String> repoIds;
}

class _RoleOption {
  const _RoleOption({
    this.roleId,
    required this.roleName,
  });

  final String? roleId;
  final String roleName;

  String get key => '${roleId ?? ''}::$roleName';
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

_RoleOption? _findRoleOption(List<_RoleOption> options, {String? roleId, String? roleName}) {
  final targetId = (roleId ?? '').toLowerCase();
  final targetName = (roleName ?? '').trim().toLowerCase();
  for (final option in options) {
    if (targetId.isNotEmpty && (option.roleId ?? '').toLowerCase() == targetId) return option;
  }
  for (final option in options) {
    if (targetName.isNotEmpty && option.roleName.trim().toLowerCase() == targetName) return option;
  }
  return null;
}

// ignore: unused_element
Future<void> _showCreateRoadmapSheetLegacy(
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
  CreateRoadmapRequest request,
) async {
  final notifier = ref.read(roadmapProvider.notifier);
  final role = request.targetRole;
  notifier.setTargetRole(request.targetRole);
  try {
    if (ref.read(roadmapProvider).statusFilter != 'active') {
      await notifier.setStatusFilter('active');
    }
    final roadmap = await notifier.generateAI(
      targetRole: request.targetRole,
      roleId: request.roleId,
      repoId: request.repoId,
      repoIds: request.repoIds,
      level: request.level,
      durationWeeks: request.durationWeeks,
      language: request.language,
      useRoleMatching: request.useRoleMatching,
      forceRegenerate: request.forceRegenerate,
      sourceMode: request.sourceMode,
    );
    if (!context.mounted || roadmap == null) return;
    AppSnackbar.show(context, message: 'Đã tạo roadmap cho $role', variant: AppSnackVariant.success);
    final roadmapId = roadmap.roadmapId?.isNotEmpty == true ? roadmap.roadmapId! : roadmap.id;
    context.push('/roadmaps/$roadmapId');
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

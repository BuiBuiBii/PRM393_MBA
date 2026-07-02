import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/roadmap_widgets.dart';
import '../../app_providers.dart';
import '../../../shared/widgets/async_content.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../utils/roadmap_recommendation.dart';
import '../utils/roadmap_utils.dart';
import '../widgets/roadmap_mobile_widgets.dart';

class RoadmapsScreen extends ConsumerStatefulWidget {
  const RoadmapsScreen({super.key});

  @override
  ConsumerState<RoadmapsScreen> createState() => _RoadmapsScreenState();
}

class _RoadmapsScreenState extends ConsumerState<RoadmapsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roadmapProvider.notifier).loadRoadmaps();
      ref.read(repositoryProvider.notifier).fetchMyAnalyses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters {
    final f = ref.read(roadmapProvider).filters;
    return f.category != 'All' || f.difficulty != 'All' || f.duration != 'All';
  }

  Future<void> _refresh() async {
    await ref.read(roadmapProvider.notifier).loadRoadmaps();
    await ref.read(repositoryProvider.notifier).fetchMyAnalyses();
  }

  void _openCreateSheet() {
    final state = ref.read(roadmapProvider);
    final analyses = ref.read(repositoryProvider).analyses;
    final roleCatalog = ref.read(roleCatalogProvider).valueOrNull ?? const <RoleCatalogItem>[];
    showCreateRoadmapSheet(
      context,
      analyses: analyses,
      roleCatalog: roleCatalog,
      selectedRole: state.selectedTargetRole,
      isGenerating: state.isGenerating,
      initialSourceMode: 'all_analyzed_repos',
      onGenerate: (request) => generateAndOpenRoadmap(context, ref, request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roadmapProvider);
    ref.watch(roleCatalogProvider);
    final analyses = ref.watch(repositoryProvider).analyses;
    final insight = buildSkillInsight(analyses);
    final filtered = filterRoadmaps(
      state.roadmaps,
      search: state.filters.search,
      category: state.filters.category,
      difficulty: state.filters.difficulty,
      duration: state.filters.duration,
    );
    final stats = state.learningStats;
    final inProgressCount = state.roadmaps.where((r) => r.progress > 0 && r.progress < 100).length;
    final isArchivedTab = state.statusFilter == 'archived';

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isGenerating ? null : _openCreateSheet,
        icon: state.isGenerating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.auto_awesome),
        label: const Text('Tạo mới'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (state.isLoading && state.roadmaps.isEmpty)
              SliverFillRemaining(
                child: ListView(
                  padding: appScreenPadding(context),
                  children: const [
                    SkeletonCard(),
                    SizedBox(height: 12),
                    SkeletonCard(),
                    SizedBox(height: 12),
                    SkeletonCard(),
                  ],
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: appScreenPadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppBadge(label: 'Roadmap cá nhân', variant: AppBadgeVariant.info),
                      const SizedBox(height: 8),
                      Text('Lộ trình của tôi', style: context.appHeadingStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        'Theo dõi tiến độ học và tạo lộ trình mới từ phân tích GitHub.',
                        style: context.appCaptionStyle,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            RoadmapStatChip(
                              icon: Icons.folder_open_outlined,
                              value: '${state.roadmaps.length}',
                              label: isArchivedTab ? 'Đã lưu trữ' : 'Đang học',
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            RoadmapStatChip(
                              icon: Icons.trending_up,
                              value: '$inProgressCount',
                              label: 'Có tiến độ',
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 10),
                            RoadmapStatChip(
                              icon: Icons.task_alt,
                              value: '${stats?.completedNodes ?? 0}/${stats?.totalNodes ?? 0}',
                              label: 'Nhiệm vụ xong',
                              color: AppColors.emerald,
                            ),
                          ],
                        ),
                      ),
                      if (insight != null) ...[
                        const SizedBox(height: 12),
                        SkillInsightExpansion(insight: insight),
                      ],
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'active', label: Text('Đang học'), icon: Icon(Icons.play_lesson_outlined, size: 16)),
                          ButtonSegment(value: 'archived', label: Text('Lưu trữ'), icon: Icon(Icons.archive_outlined, size: 16)),
                        ],
                        selected: {state.statusFilter},
                        onSelectionChanged: state.isLoading
                            ? null
                            : (value) => ref.read(roadmapProvider.notifier).setStatusFilter(value.first),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Tìm roadmap, kỹ năng...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: state.filters.search.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          ref.read(roadmapProvider.notifier).setFilters(state.filters.copyWith(search: ''));
                                        },
                                      )
                                    : null,
                                isDense: true,
                              ),
                              onChanged: (v) => ref.read(roadmapProvider.notifier).setFilters(state.filters.copyWith(search: v)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Badge(
                            isLabelVisible: _hasActiveFilters,
                            smallSize: 8,
                            child: IconButton.filledTonal(
                              tooltip: 'Bộ lọc',
                              onPressed: () => showRoadmapFilterSheet(
                                context,
                                state.filters,
                                (next) => ref.read(roadmapProvider.notifier).setFilters(next),
                              ),
                              icon: const Icon(Icons.tune),
                            ),
                          ),
                        ],
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(state.error!, style: const TextStyle(color: AppColors.amber, fontSize: 13)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isArchivedTab ? 'Kho lưu trữ' : 'Đang học',
                            style: context.appSectionTitleStyle,
                          ),
                          AppBadge(label: '${filtered.length} lộ trình'),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: appScreenPadding(context),
                    child: EmptyState(
                      title: state.roadmaps.isEmpty
                          ? (isArchivedTab ? 'Chưa có roadmap lưu trữ' : 'Chưa có roadmap')
                          : 'Không khớp bộ lọc',
                      subtitle: state.roadmaps.isEmpty
                          ? (isArchivedTab
                              ? 'Roadmap lưu trữ sẽ xuất hiện ở đây.'
                              : 'Tạo roadmap đầu tiên từ đề xuất AI hoặc chọn vai trò mục tiêu.')
                          : 'Thử từ khóa hoặc bộ lọc khác.',
                      action: state.roadmaps.isEmpty && !isArchivedTab
                          ? PrimaryButton(
                              label: 'Tạo roadmap',
                              icon: Icons.auto_awesome,
                              onPressed: state.isGenerating ? null : _openCreateSheet,
                            )
                          : null,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    appScreenPadding(context).left,
                    0,
                    appScreenPadding(context).right,
                    96 + MediaQuery.paddingOf(context).bottom,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final roadmap = filtered[index];
                        final taskCount = taskCountFor(roadmap);
                        final routeId = roadmap.roadmapId?.isNotEmpty == true ? roadmap.roadmapId! : roadmap.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RoadmapCompactCard(
                            roadmap: roadmap,
                            taskCount: taskCount,
                            onTap: () => context.push('/roadmaps/$routeId'),
                            onContinue: () => context.push('/roadmaps/$routeId'),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class RoadmapDetailScreen extends ConsumerStatefulWidget {
  const RoadmapDetailScreen({super.key, required this.roadmapId});

  final String roadmapId;

  @override
  ConsumerState<RoadmapDetailScreen> createState() => _RoadmapDetailScreenState();
}

class _RoadmapDetailScreenState extends ConsumerState<RoadmapDetailScreen> {
  int _selectedTab = 0; // 0: Lộ trình, 1: Mục tiêu, 2: Hướng bổ trợ

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (ref.read(roadmapProvider.notifier).getById(widget.roadmapId) == null) {
        await ref.read(roadmapProvider.notifier).fetchRoadmap(widget.roadmapId);
      }
    });
  }

  Widget _tabButton(BuildContext context, int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.appCardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.primary : context.appTextSecondary,
              ),
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

  Widget _sectionHeader(BuildContext context, String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(title, style: context.appSectionTitleStyle),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final roadmapState = ref.watch(roadmapProvider);
    final roadmap = ref.read(roadmapProvider.notifier).getById(widget.roadmapId);

    return AsyncPageBody(
      isLoading: roadmapState.isLoading && roadmap == null,
      hasData: roadmap != null,
      onRetry: () => ref.read(roadmapProvider.notifier).fetchRoadmap(widget.roadmapId),
      child: roadmap == null
          ? const SizedBox.shrink()
          : Builder(
              builder: (context) {
                final progress = ref.read(roadmapProvider.notifier).progressFor(roadmap);
                final percent = progress.total == 0 ? 0 : ((progress.completed / progress.total) * 100).round();
                final notifier = ref.read(roadmapProvider.notifier);

                return ListView(
      padding: appScreenPadding(context),
      children: [
        PageHeader(
          title: roadmap.title,
          subtitle: roadmap.subtitle,
          trailing: roadmap.isArchived
              ? null
              : PrimaryButton(
                  label: 'Lưu trữ',
                  outlined: true,
                  loading: roadmapState.isArchiving,
                  onPressed: roadmapState.isArchiving
                      ? null
                      : () async {
                          try {
                            await notifier.archiveRoadmap(roadmap.id);
                            if (!context.mounted) return;
                            context.go('/roadmaps');
                          } catch (_) {}
                        },
                ),
        ),
        if (roadmap.isArchived) ...[
          const AppBadge(label: 'Đã lưu trữ', variant: AppBadgeVariant.warning),
          const SizedBox(height: 8),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role-matching origin badge
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
              // Role match info
              if (roadmap.roleMatchInfo != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.work_outline, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${roadmap.roleMatchInfo!['roleName'] ?? roadmap.roleMatchInfo!['matchedRole'] ?? roadmap.careerOutcome}'
                        '  •  ${(roadmap.roleMatchInfo!['matchScore'] ?? 0.0).toStringAsFixed(1)}%'
                        '  •  ${roadmap.roleMatchInfo!['matchLevelLabel'] ?? roadmap.roleMatchInfo!['matchLevel'] ?? ''}',
                        style: context.appLabelStyle,
                      ),
                    ),
                  ],
                ),
              ],
              // Skill gap summary
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
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: context.appBubbleAiBg,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _tabButton(context, 0, 'Lộ trình', Icons.alt_route),
              _tabButton(context, 1, 'Mục tiêu', Icons.track_changes),
              _tabButton(context, 2, 'Bổ trợ', Icons.extension),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedTab == 0) ...[
          Text('Cây lộ trình', style: context.appSectionTitleStyle),
          const SizedBox(height: 8),
          RoadmapTreeWidget(
            roadmap: roadmap,
            onStatusChange: (nodeId, status) => notifier.updateNodeStatus(roadmap.id, nodeId, status),
            onBookmarkToggle: notifier.toggleBookmark,
            isBookmarked: notifier.isBookmarked,
          ),
          const SizedBox(height: 16),
          LearningTimelineWidget(roadmap: roadmap),
        ],
        if (_selectedTab == 1) ...[
          _sectionHeader(context, 'Mục tiêu học tập', Icons.flag, AppColors.primary),
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
                children: roadmap.objectives.map((obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(obj, style: context.appBodyStyle)),
                    ],
                  ),
                )).toList(),
              ),
            ),
          const SizedBox(height: 16),
          _sectionHeader(context, 'Kỹ năng hiện có', Icons.star_border, AppColors.emerald),
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
          _sectionHeader(context, 'Kỹ năng cần bổ sung', Icons.warning_amber_rounded, AppColors.amber),
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
        if (_selectedTab == 2) ...[
          if (roadmap.supportingPaths.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('Không có hướng đi bổ trợ nào.', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            )
          else
            ...roadmap.supportingPaths.map((path) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.explore, color: AppColors.cyan, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            path.title,
                            style: context.appSectionTitleStyle.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      path.reason,
                      style: context.appBodyStyle,
                    ),
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
                    ...path.suggestedTasks.map((task) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.cyan)),
                          Expanded(
                            child: Text(
                              task,
                              style: context.appBodyStyle.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            )),
        ],
      ],
    );
              },
            ),
    );
  }
}

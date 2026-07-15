import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/scroll_list_hints.dart';
import '../../../shared/widgets/collapsible_list.dart';
import '../../../shared/widgets/skeleton_loading.dart';
import '../../feature_providers.dart';
import '../utils/roadmap_recommendation.dart';
import '../utils/roadmap_utils.dart';
import '../utils/roadmap_generate_helper.dart';
import '../widgets/create_roadmap_sheet.dart';
import '../widgets/roadmap_list_header.dart';
import '../widgets/roadmap_mobile_widgets.dart';

class RoadmapsScreen extends ConsumerStatefulWidget {
  const RoadmapsScreen({super.key});

  @override
  ConsumerState<RoadmapsScreen> createState() => _RoadmapsScreenState();
}

class _RoadmapsScreenState extends ConsumerState<RoadmapsScreen> {
  final _searchController = TextEditingController();
  static const _initialVisibleCount = 5;
  bool _roadmapsExpanded = false;
  Object? _listResetKey;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(roadmapProvider.notifier).loadRoadmaps(status: 'active');
      final analyses = ref.read(repositoryProvider).analyses;
      if (analyses.isEmpty) {
        ref.read(repositoryProvider.notifier).fetchMyAnalyses();
      } else {
        ref.read(repositoryProvider.notifier).calculateRoleMatches(
              sourceMode: 'all_analyzed_repos',
              forceRefresh: false,
            );
      }
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
    await Future.wait([
      ref.read(roadmapProvider.notifier).loadRoadmaps(),
      ref.read(repositoryProvider.notifier).fetchMyAnalyses(),
    ]);
  }

  void _openCreateSheet() {
    if (ref.read(roadmapProvider).isGenerating) return;
    showCreateRoadmapSheet(
      context,
      config: CreateRoadmapSheetConfig(
        sourceMode: 'all_analyzed_repos',
        onGenerate: (params) => generateAndOpenRoadmap(context, ref, params),
      ),
    );
  }

  Future<void> _deleteRoadmap(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa roadmap?'),
        content: Text('Roadmap "$title" sẽ bị xóa khỏi danh sách của bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(roadmapProvider.notifier).deleteRoadmap(id);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(roadmapProvider).error ?? 'Không thể xóa roadmap.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roadmapProvider);
    final analyses = ref.watch(repositoryProvider).analyses;
    final insight = buildSkillInsight(analyses);
    final filtered = filterRoadmaps(
      state.roadmaps,
      search: state.filters.search,
      category: state.filters.category,
      difficulty: state.filters.difficulty,
      duration: state.filters.duration,
    );
    final inProgressCount =
        state.roadmaps.where((r) => r.progress > 0 && r.progress < 100).length;
    final notifier = ref.read(roadmapProvider.notifier);
    final listResetKey = Object.hash(
      state.statusFilter,
      state.filters.search,
      state.filters.category,
      state.filters.difficulty,
      state.filters.duration,
      filtered.length,
    );
    if (_listResetKey != listResetKey) {
      _listResetKey = listResetKey;
      _roadmapsExpanded = false;
    }
    final canCollapseRoadmaps = filtered.length > _initialVisibleCount;
    final visibleRoadmapCount = (!_roadmapsExpanded && canCollapseRoadmaps)
        ? _initialVisibleCount
        : filtered.length;

    final showFab = filtered.isNotEmpty;

    return Scaffold(
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: state.isGenerating ? null : _openCreateSheet,
              icon: state.isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome),
              label: const Text('Tạo mới'),
            )
          : null,
      body: ScrollListHints(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (state.isLoading &&
                  state.roadmaps.isEmpty &&
                  state.statusFilter == 'active')
                SliverFillRemaining(
                  child: ListView(
                    padding: appScreenPadding(context),
                    children: const [
                      SkeletonCard(),
                      SizedBox(height: 12),
                      SkeletonCard(),
                      SizedBox(height: 12),
                      SkeletonCard()
                    ],
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: appScreenPadding(context),
                    child: RoadmapListHeader(
                      state: state,
                      searchController: _searchController,
                      hasActiveFilters: _hasActiveFilters,
                      filteredCount: filtered.length,
                      inProgressCount: inProgressCount,
                      insight: insight,
                      onSearchChanged: (v) => notifier
                          .setFilters(state.filters.copyWith(search: v)),
                      onClearSearch: () {
                        _searchController.clear();
                        notifier.setFilters(state.filters.copyWith(search: ''));
                      },
                      onOpenFilters: () => showRoadmapFilterSheet(
                        context,
                        state.filters,
                        notifier.setFilters,
                        categories:
                            deriveRoadmapCategoryFilters(state.roadmaps),
                      ),
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
                            ? 'Chưa có roadmap'
                            : 'Không khớp bộ lọc',
                        subtitle: state.roadmaps.isEmpty
                            ? 'Tạo roadmap đầu tiên từ đề xuất AI hoặc chọn vai trò mục tiêu.'
                            : 'Thử từ khóa hoặc bộ lọc khác.',
                        action: state.roadmaps.isEmpty
                            ? PrimaryButton(
                                label: 'Tạo roadmap',
                                icon: Icons.auto_awesome,
                                loading: state.isGenerating,
                                onPressed: state.isGenerating
                                    ? null
                                    : _openCreateSheet,
                              )
                            : null,
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      appScreenPadding(context).left,
                      0,
                      appScreenPadding(context).right,
                      canCollapseRoadmaps && !_roadmapsExpanded
                          ? 0
                          : 96 + MediaQuery.paddingOf(context).bottom,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final roadmap = filtered[index];
                          final taskCount = taskCountFor(roadmap);
                          final id = roadmap.slug.isNotEmpty
                              ? roadmap.slug
                              : roadmap.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RoadmapCompactCard(
                              roadmap: roadmap,
                              taskCount: taskCount,
                              onTap: () => context.push('/roadmaps/$id'),
                              onContinue: () => context.push('/roadmaps/$id'),
                              onDelete: state.deletingRoadmapId == null
                                  ? () => _deleteRoadmap(
                                        roadmap.id,
                                        roadmap.title,
                                      )
                                  : null,
                            ),
                          );
                        },
                        childCount: visibleRoadmapCount,
                      ),
                    ),
                  ),
                  if (canCollapseRoadmaps)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          appScreenPadding(context).left,
                          0,
                          appScreenPadding(context).right,
                          96 + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: ShowMoreListToggle(
                          expanded: _roadmapsExpanded,
                          hiddenCount: filtered.length - _initialVisibleCount,
                          onToggle: () => setState(
                              () => _roadmapsExpanded = !_roadmapsExpanded),
                        ),
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

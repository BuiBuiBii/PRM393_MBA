import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../providers/roadmap_provider.dart';
import '../utils/roadmap_recommendation.dart';
import 'roadmap_mobile_widgets.dart';

/// Header: stats, tab lọc, search, filter cho màn danh sách roadmap.
class RoadmapListHeader extends StatelessWidget {
  const RoadmapListHeader({
    super.key,
    required this.state,
    required this.searchController,
    required this.hasActiveFilters,
    required this.filteredCount,
    required this.inProgressCount,
    required this.insight,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilters,
  });

  final RoadmapState state;
  final TextEditingController searchController;
  final bool hasActiveFilters;
  final int filteredCount;
  final int inProgressCount;
  final SkillInsightSummary? insight;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final stats = state.learningStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBadge(label: 'Roadmap cá nhân', variant: AppBadgeVariant.info),
        const SizedBox(height: 8),
        Text('Lộ trình của tôi',
            style: context.appHeadingStyle
                .copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
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
                label: 'Đang học',
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
                value:
                    '${stats?.completedNodes ?? 0}/${stats?.totalNodes ?? 0}',
                label: 'Nhiệm vụ xong',
                color: AppColors.emerald,
              ),
            ],
          ),
        ),
        if (insight != null) ...[
          const SizedBox(height: 12),
          SkillInsightExpansion(insight: insight!),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm roadmap, kỹ năng...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.filters.search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: onClearSearch,
                        )
                      : null,
                  isDense: true,
                ),
                onChanged: onSearchChanged,
              ),
            ),
            const SizedBox(width: 8),
            Badge(
              isLabelVisible: hasActiveFilters,
              smallSize: 8,
              child: IconButton.filledTonal(
                tooltip: 'Bộ lọc',
                onPressed: onOpenFilters,
                icon: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        if (state.roadmaps.isEmpty && state.error != null) ...[
          const SizedBox(height: 12),
          Text(state.error!,
              style: const TextStyle(color: AppColors.amber, fontSize: 13)),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Đang học', style: context.appSectionTitleStyle),
            AppBadge(label: '$filteredCount lộ trình'),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

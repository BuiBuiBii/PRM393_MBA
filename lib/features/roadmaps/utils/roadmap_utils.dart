import '../../../shared/models/app_models.dart';
import '../../../shared/widgets/app_widgets.dart';

List<RoadmapModel> filterRoadmaps(
  List<RoadmapModel> roadmaps, {
  required String search,
  required String category,
  required String difficulty,
  required String duration,
}) {
  final query = search.trim().toLowerCase();

  return roadmaps.where((roadmap) {
    if (query.isNotEmpty) {
      final haystack = [
        roadmap.title,
        roadmap.subtitle,
        roadmap.careerOutcome,
        ...roadmap.tags
      ].join(' ').toLowerCase();
      if (!haystack.contains(query)) return false;
    }
    if (category != 'All' && roadmap.category != category) return false;
    if (difficulty != 'All' && roadmap.difficulty != difficulty) return false;
    if (duration == 'Short' && roadmap.estimatedWeeks > 6) return false;
    if (duration == 'Medium' &&
        (roadmap.estimatedWeeks <= 6 || roadmap.estimatedWeeks > 10))
      return false;
    if (duration == 'Long' && roadmap.estimatedWeeks <= 10) return false;
    return true;
  }).toList();
}

String formatCategoryFilter(String category) {
  if (category == 'All') return 'Tất cả danh mục';
  return category;
}

String formatDifficultyFilter(String difficulty) {
  switch (difficulty) {
    case 'All':
      return 'Tất cả cấp độ';
    case 'Beginner':
      return 'Cơ bản';
    case 'Intermediate':
      return 'Trung cấp';
    case 'Advanced':
      return 'Nâng cao';
    default:
      return difficulty;
  }
}

String formatDurationFilter(String duration) {
  switch (duration) {
    case 'All':
      return 'Tất cả thời lượng';
    case 'Short':
      return 'Ngắn (≤6 tuần)';
    case 'Medium':
      return 'Trung bình (7–10 tuần)';
    case 'Long':
      return 'Dài (>10 tuần)';
    default:
      return duration;
  }
}

/// Danh mục lọc lấy từ roadmap thật của user (không hard-code).
List<String> deriveRoadmapCategoryFilters(List<RoadmapModel> roadmaps) {
  final values = roadmaps
      .map((r) => r.category.trim())
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return ['All', ...values];
}

String formatDifficultyBadge(String difficulty) {
  switch (difficulty) {
    case 'Beginner':
      return 'Cơ bản';
    case 'Intermediate':
      return 'Trung cấp';
    case 'Advanced':
      return 'Nâng cao';
    default:
      return difficulty;
  }
}

AppBadgeVariant difficultyVariant(String difficulty) {
  switch (difficulty) {
    case 'Beginner':
      return AppBadgeVariant.success;
    case 'Intermediate':
      return AppBadgeVariant.info;
    case 'Advanced':
      return AppBadgeVariant.warning;
    default:
      return AppBadgeVariant.neutral;
  }
}

int taskCountFor(RoadmapModel roadmap) {
  return roadmap.modules
      .fold<int>(0, (sum, module) => sum + module.nodes.length);
}

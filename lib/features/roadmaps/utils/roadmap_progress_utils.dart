import '../../../core/network/normalizers.dart';
import '../../../shared/models/app_models.dart';

/// Tính % hoàn thành từ trạng thái node; fallback `progressSummary` từ BE.
int roadmapProgressPercent(RoadmapModel roadmap) {
  var completed = 0;
  var total = 0;
  for (final module in roadmap.modules) {
    for (final node in module.nodes) {
      total++;
      if (node.status == 'completed') completed++;
    }
  }
  if (total > 0 && completed > 0) {
    return ((completed / total) * 100).round();
  }

  final summaryProgress = int.tryParse(
    roadmap.progressSummary?['overallProgress']?.toString() ?? '',
  );
  if (summaryProgress != null && summaryProgress > 0) {
    return summaryProgress;
  }
  if (roadmap.progress > 0) return roadmap.progress;
  if (total == 0) return 0;
  return ((completed / total) * 100).round();
}

RoadmapModel mergeRoadmapProgressPayload(
  RoadmapModel roadmap,
  Map<String, dynamic> payload,
) {
  final summary = payload['progressSummary'] is Map
      ? Map<String, dynamic>.from(payload['progressSummary'] as Map)
      : roadmap.progressSummary;
  final statuses = <String, String>{};
  for (final item
      in (payload['items'] as List? ?? const []).whereType<Map>()) {
    final itemId = (item['itemId'] ?? '').toString();
    if (itemId.isNotEmpty) {
      statuses[itemId] = (item['status'] ?? 'not_started').toString();
    }
  }

  if (statuses.isEmpty && summary == null) return roadmap;

  final modules = roadmap.modules.map((module) {
    final nodes = module.nodes.map((node) {
      final nextStatus = statuses[node.id];
      return nextStatus == null
          ? node
          : node.copyWith(status: mapRoadmapTaskStatus(nextStatus));
    }).toList();
    return RoadmapModuleModel(
      id: module.id,
      title: module.title,
      description: module.description,
      nodes: nodes,
    );
  }).toList();

  final merged = roadmap.copyWith(
    modules: modules,
    progressSummary: summary ?? roadmap.progressSummary,
  );
  return merged.copyWith(progress: roadmapProgressPercent(merged));
}

({int completed, int total}) roadmapNodeCounts(RoadmapModel roadmap) {
  var completed = 0;
  var total = 0;
  for (final module in roadmap.modules) {
    for (final node in module.nodes) {
      total++;
      if (node.status == 'completed') completed++;
    }
  }
  return (completed: completed, total: total);
}

List<RoadmapModel> applyStoredNodeProgress(
  List<RoadmapModel> roadmaps,
  Map<String, Map<String, String>> storedStatuses, {
  Set<String> bookmarkIds = const {},
}) {
  if (storedStatuses.isEmpty && bookmarkIds.isEmpty) {
    return roadmaps.map(_syncRoadmapProgress).toList();
  }

  return roadmaps.map((roadmap) {
    final nodeStatuses =
        storedStatuses[roadmap.id] ?? storedStatuses[roadmap.slug] ?? {};
    if (nodeStatuses.isEmpty && bookmarkIds.isEmpty) {
      return _syncRoadmapProgress(roadmap);
    }

    final modules = roadmap.modules.map((module) {
      final nodes = module.nodes.map((node) {
        var next = node;
        final stored = nodeStatuses[node.id];
        if (stored != null && stored.isNotEmpty) {
          next = next.copyWith(status: stored);
        }
        if (bookmarkIds.contains(node.id)) {
          next = next.copyWith(bookmarked: true);
        }
        return next;
      }).toList();
      return RoadmapModuleModel(
        id: module.id,
        title: module.title,
        description: module.description,
        nodes: nodes,
      );
    }).toList();

    return roadmap.copyWith(
      modules: modules,
      progress: roadmapProgressPercent(roadmap.copyWith(modules: modules)),
    );
  }).toList();
}

RoadmapModel _syncRoadmapProgress(RoadmapModel roadmap) {
  final percent = roadmapProgressPercent(roadmap);
  if (percent == roadmap.progress) return roadmap;
  return roadmap.copyWith(progress: percent);
}

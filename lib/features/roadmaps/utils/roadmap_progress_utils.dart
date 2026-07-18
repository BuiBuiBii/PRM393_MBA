import '../../../shared/models/app_models.dart';

/// Tính % hoàn thành từ trạng thái node thực tế.
int roadmapProgressPercent(RoadmapModel roadmap) {
  var completed = 0;
  var total = 0;
  for (final module in roadmap.modules) {
    for (final node in module.nodes) {
      total++;
      if (node.status == 'completed') completed++;
    }
  }
  if (total == 0) return 0;
  return ((completed / total) * 100).round();
}

/// Merges the backend progress source of truth into roadmap task metadata.
///
/// Task metadata comes from the roadmap detail endpoint, while task status and
/// the header percentage must come from the dedicated progress endpoint.
RoadmapModel mergeRoadmapProgress(
  RoadmapModel roadmap,
  Map<String, dynamic> payload,
) {
  final summary = payload['progressSummary'] is Map
      ? Map<String, dynamic>.from(payload['progressSummary'] as Map)
      : <String, dynamic>{};
  final statuses = <String, String>{};

  for (final rawItem
      in (payload['items'] as List? ?? const []).whereType<Map>()) {
    final item = Map<String, dynamic>.from(rawItem);
    final itemId = (item['itemId'] ?? '').toString();
    if (itemId.isNotEmpty) {
      statuses[itemId] = _mapBackendTaskStatus(item['status']?.toString());
    }
  }

  final modules = roadmap.modules.map((module) {
    final nodes = module.nodes.map((node) {
      final status = statuses[node.id];
      return status == null ? node : node.copyWith(status: status);
    }).toList();
    return RoadmapModuleModel(
      id: module.id,
      title: module.title,
      description: module.description,
      nodes: nodes,
    );
  }).toList();

  final overallProgress =
      int.tryParse(summary['overallProgress']?.toString() ?? '') ??
          roadmap.progress;
  return roadmap.copyWith(
    modules: modules,
    progress: overallProgress.clamp(0, 100),
    progressSummary: summary.isEmpty ? roadmap.progressSummary : summary,
  );
}

String _mapBackendTaskStatus(String? status) {
  switch (status) {
    case 'completed':
      return 'completed';
    case 'in_progress':
      return 'in-progress';
    default:
      return 'unlocked';
  }
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

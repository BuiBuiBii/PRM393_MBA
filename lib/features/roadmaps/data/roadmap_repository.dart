import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';

class RoadmapRepository {
  RoadmapRepository(this._api);

  final AppApi _api;

  Future<List<RoadmapModel>> getMyRoadmaps({String? status, String? targetRole}) =>
      _api.getMyRoadmaps(status: status, targetRole: targetRole);

  Future<RoadmapModel> generateRoadmap({
    required String targetRole,
    String? repoId,
    String level = 'beginner',
    int durationWeeks = 6,
    String language = 'vi',
    bool forceRegenerate = false,
  }) =>
      _api.generateRoadmap(
        targetRole: targetRole,
        repoId: repoId,
        level: level,
        durationWeeks: durationWeeks,
        language: language,
        forceRegenerate: forceRegenerate,
      );

  Future<RoadmapModel> getRoadmap(String id) => _api.getRoadmap(id);

  Future<RoadmapModel> archiveRoadmap(String id) => _api.archiveRoadmap(id);

  Future<Map<String, dynamic>> getMyProgress() => _api.getMyProgress();
}

final roadmapRepositoryProvider = Provider<RoadmapRepository>(
  (ref) => RoadmapRepository(ref.read(appApiProvider)),
);

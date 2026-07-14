import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';
import '../models/roadmap_generate_params.dart';

class RoadmapRepository {
  RoadmapRepository(this._api);

  final AppApi _api;

  Future<List<RoadmapModel>> getMyRoadmaps(
          {String? status, String? targetRole}) =>
      _api.getMyRoadmaps(status: status, targetRole: targetRole);

  Future<RoadmapModel> generateRoadmap(RoadmapGenerateParams params) =>
      _api.generateRoadmap(params);

  Future<RoadmapModel> getRoadmap(String id) => _api.getRoadmap(id);

  Future<RoadmapModel> archiveRoadmap(String id) => _api.archiveRoadmap(id);

  Future<Map<String, String>> getLearningAvailability(String roadmapId) =>
      _api.getRoadmapLearningAvailability(roadmapId);

  Future<LearningContentModel> getLearning(String roadmapId, String itemId) =>
      _api.getRoadmapLearning(roadmapId, itemId);

  Future<LearningContentModel> generateLearning(
          String roadmapId, String itemId) =>
      _api.generateRoadmapLearning(roadmapId, itemId);

  Future<Map<String, dynamic>> updateProgress(
          String roadmapId, String itemId, String status) =>
      _api.updateRoadmapProgress(roadmapId, itemId, status);

  Future<Map<String, dynamic>> getProgress(String roadmapId) =>
      _api.getRoadmapProgress(roadmapId);

  Future<Map<String, dynamic>> getMyProgress() => _api.getMyProgress();
}

final roadmapRepositoryProvider = Provider<RoadmapRepository>(
  (ref) => RoadmapRepository(ref.read(appApiProvider)),
);

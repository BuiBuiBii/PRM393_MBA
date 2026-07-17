import 'package:dio/dio.dart';

import '../../core/constants/dev2vec_roles.dart';
import '../../core/network/api_utils.dart';
import '../../core/network/normalizers.dart';
import '../../shared/models/app_models.dart';
import '../../features/roadmaps/models/roadmap_generate_params.dart';

class AppApi {
  AppApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> dashboardMe() async {
    final res = await _dio.get('/dashboard/me');
    return normalizeDashboard(res.data);
  }

  Future<List<RepositoryModel>> getCachedRepositories() async {
    final res = await _dio.get('/github/repositories/cached');
    return normalizeRepositories(res.data);
  }

  Future<List<RepositoryModel>> syncRepositories() async {
    final res = await _dio.get('/github/repositories');
    return normalizeRepositories(res.data);
  }

  Future<RepositoryModel> getRepository(String id) async {
    final res = await _dio.get('/github/repositories/$id');
    return normalizeRepository(res.data);
  }

  Future<List<dynamic>> getCachedPackages(String id) async {
    final res = await _dio.get('/github/repositories/$id/packages/cached');
    return normalizeRepoPayloadList(res.data);
  }

  Future<List<dynamic>> syncPackages(String id) async {
    final res = await _dio.get('/github/repositories/$id/packages');
    return normalizeRepoPayloadList(res.data);
  }

  Future<List<dynamic>> getCachedCommits(String id) async {
    final res = await _dio.get('/github/repositories/$id/commits/cached');
    return normalizeRepoPayloadList(res.data);
  }

  Future<List<dynamic>> syncCommits(String id) async {
    final res = await _dio.get('/github/repositories/$id/commits');
    return normalizeRepoPayloadList(res.data);
  }

  Future<void> completeGitHubOAuthCallback(
      Map<String, String> queryParams) async {
    await _dio.get('/github/oauth/callback', queryParameters: queryParams);
  }

  Future<AnalysisModel> analyzeRepository(
    String id, {
    String view = 'detail',
    bool includeEvidence = false,
  }) async {
    final res = await _dio.post(
      '/analysis/repositories/$id',
      queryParameters: {
        'view': view,
        'includeEvidence': includeEvidence,
      },
      options: Options(receiveTimeout: const Duration(minutes: 3)),
    );
    return normalizeAnalysis(res.data, repositoryId: id);
  }

  Future<AnalysisModel?> getAnalysis(String id) async {
    final res = await _dio.get('/analysis/results/$id');
    return normalizeAnalysis(res.data);
  }

  Future<RoleMatchModel?> calculateRoleMatches({
    required String sourceMode,
    String? repoId,
    List<String>? repoIds,
    int limit = 3,
  }) async {
    final body = <String, dynamic>{
      'sourceMode': sourceMode,
      'limit': limit,
      if (repoId != null && repoId.isNotEmpty) 'repoId': repoId,
      if (repoIds != null && repoIds.isNotEmpty) 'repoIds': repoIds,
    };
    final res = await _dio.post('/analysis/role-matches', data: body);
    final data = unwrapResponse<dynamic>(res.data);
    if (data == null) return null;
    return RoleMatchModel.fromJson(
        Map<String, dynamic>.from(data as Map? ?? {}));
  }

  /// Legacy single-repo — fallback nếu POST lỗi.
  Future<RoleMatchModel?> getRoleMatches(
    String repoId, {
    int? limit,
    String? targetRole,
    bool includeDetails = true,
  }) async {
    final res = await _dio.get(
      '/analysis/repositories/$repoId/role-matches',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (targetRole != null && targetRole.isNotEmpty)
          'targetRole': targetRole,
        'includeDetails': includeDetails,
      },
    );
    final data = unwrapResponse<dynamic>(res.data);
    if (data == null) return null;
    return RoleMatchModel.fromJson(
        Map<String, dynamic>.from(data as Map? ?? {}));
  }

  Future<List<Dev2VecRole>> getRoleCatalog() async {
    final res = await _dio.get('/roles/catalog');
    final data = unwrapResponse<dynamic>(res.data);
    final roles = (data is Map ? data['roles'] : data) as List? ?? [];
    return roles
        .whereType<Map>()
        .map((e) => Dev2VecRole.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  Future<List<AnalysisModel>> getMyAnalyses() async {
    final res = await _dio.get('/analysis/me');
    return normalizeAnalyses(res.data);
  }

  Future<List<RepoAnalysisSnapshotModel>> getSnapshots(String repoId) async {
    final res = await _dio.get('/repositories/$repoId/snapshots');
    return normalizeSnapshots(res.data);
  }

  Future<RepoAnalysisSnapshotModel?> getSnapshot(String snapshotId) async {
    final res = await _dio.get('/snapshots/$snapshotId');
    return normalizeSnapshot(res.data);
  }

  Future<SnapshotCompareResultModel> getProgressComparison(
      String repoId) async {
    final res = await _dio.get('/repositories/$repoId/progress-comparison');
    return normalizeSnapshotCompare(res.data);
  }

  Future<AiFeedbackModel> generateAiFeedback(
    String repoId, {
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) async {
    final res = await _dio.post('/ai-feedback/repositories/$repoId', data: {
      if (roadmapId != null && roadmapId.isNotEmpty) 'roadmapId': roadmapId,
      if (analysisId != null && analysisId.isNotEmpty) 'analysisId': analysisId,
      if (snapshotId != null && snapshotId.isNotEmpty) 'snapshotId': snapshotId,
    });
    return normalizeAiFeedback(res.data);
  }

  Future<AiFeedbackModel?> getAiFeedback(String repoId,
      {String? roadmapId}) async {
    final res = await _dio.get(
      '/ai-feedback/results/$repoId',
      queryParameters: {
        if (roadmapId != null && roadmapId.isNotEmpty) 'roadmapId': roadmapId,
      },
    );
    return normalizeAiFeedback(res.data);
  }

  Future<List<AiFeedbackModel>> getMyAiFeedback() async {
    final res = await _dio.get('/ai-feedback/me');
    return normalizeAiFeedbacks(res.data);
  }

  Future<Map<String, dynamic>> getGitHubAccount() async {
    final res = await _dio.get('/github/account');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<Map<String, dynamic>> disconnectGitHub() async {
    final res = await _dio.delete('/github/account');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<List<ChatSessionModel>> getChatSessions() async {
    final res = await _dio.get('/chat/sessions');
    return normalizeChatSessions(res.data);
  }

  Future<ChatSessionModel> createChatSession(
    Object payload, {
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) async {
    final data = switch (payload) {
      ChatSessionCreatePayload value => value.toJson(),
      String title => ChatSessionCreatePayload(
          title: title,
          repositoryId: repositoryId,
          roadmapId: roadmapId,
          analysisId: analysisId,
          snapshotId: snapshotId,
        ).toJson(),
      Map value => Map<String, dynamic>.from(value),
      _ => throw ArgumentError('Unsupported chat session payload'),
    };
    final res = await _dio.post('/chat/sessions', data: data);
    return normalizeChatSession(res.data);
  }

  Future<void> deleteChatSession(String sessionId) async {
    await _dio.delete('/chat/sessions/$sessionId');
  }

  Future<ChatSessionModel> getChatSession(String id) async {
    final res = await _dio.get('/chat/sessions/$id');
    return normalizeChatSessionDetail(res.data);
  }

  Future<ChatSendResult> sendChatMessage(
    String sessionId,
    String message, {
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) async {
    final res = await _dio.post('/chat/sessions/$sessionId/messages', data: {
      'message': message,
      if (repositoryId != null && repositoryId.isNotEmpty)
        'repositoryId': repositoryId,
      if (roadmapId != null && roadmapId.isNotEmpty) 'roadmapId': roadmapId,
      if (analysisId != null && analysisId.isNotEmpty) 'analysisId': analysisId,
      if (snapshotId != null && snapshotId.isNotEmpty) 'snapshotId': snapshotId,
    });
    return normalizeChatSendResult(res.data);
  }

  Future<List<NotificationModel>> getNotifications(
      {bool unreadOnly = false, String? type}) async {
    final res = await _dio.get('/notifications/me', queryParameters: {
      'page': 1,
      'limit': 20,
      if (unreadOnly) 'unreadOnly': true,
      if (type != null && type.isNotEmpty) 'type': type,
    });
    return normalizeNotifications(res.data);
  }

  Future<void> createNotification(
      {required String title,
      required String message,
      String type = 'SYSTEM'}) async {
    await _dio.post('/notifications',
        data: {'title': title, 'message': message, 'type': type});
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }

  Future<void> deleteNotification(String id) async {
    await _dio.delete('/notifications/$id');
  }

  Future<ProfileModel> getProfile() async {
    final res = await _dio.get('/profiles/me');
    return normalizeProfile(res.data);
  }

  Future<ProfileModel> saveProfile(ProfileModel profile,
      {bool exists = false}) async {
    final res = exists
        ? await _dio.patch('/profiles/me', data: profile.toJson())
        : await _dio.post('/profiles', data: profile.toJson());
    return normalizeProfile(res.data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
  }

  Future<List<RoadmapModel>> getMyRoadmaps(
      {String? status, String? targetRole}) async {
    final res = await _dio.get('/roadmaps/me', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (targetRole != null && targetRole.isNotEmpty) 'targetRole': targetRole,
    });
    return normalizeRoadmaps(res.data);
  }

  Future<RoadmapModel> generateRoadmap(RoadmapGenerateParams params) async {
    final res = await _dio.post('/roadmaps/generate', data: params.toJson());
    return normalizeRoadmap(res.data);
  }

  Future<RoadmapModel> getRoadmap(String id) async {
    final res = await _dio.get('/roadmaps/$id');
    return normalizeRoadmap(res.data);
  }

  Future<Map<String, String>> getRoadmapLearningAvailability(
      String roadmapId) async {
    final res = await _dio.get('/roadmaps/$roadmapId/learning');
    final data = toRecord(unwrapResponse<dynamic>(res.data));
    final items = data['items'] as List? ?? const [];
    return {
      for (final item in items.whereType<Map>())
        if ((item['itemId'] ?? '').toString().isNotEmpty)
          item['itemId'].toString():
              (item['learningStatus'] ?? 'missing').toString(),
    };
  }

  Future<LearningContentModel> getRoadmapLearning(
      String roadmapId, String itemId) async {
    final res = await _dio.get(
      '/roadmaps/$roadmapId/learning/items/$itemId',
      queryParameters: const {'includeResources': true},
    );
    final data = toRecord(unwrapResponse<dynamic>(res.data));
    return LearningContentModel.fromJson(toRecord(data['learning']));
  }

  Future<LearningContentModel> generateRoadmapLearning(
      String roadmapId, String itemId) async {
    final res = await _dio.post(
      '/roadmaps/$roadmapId/learning/items/$itemId/generate',
      data: const {'forceRegenerate': false, 'includeResources': true},
    );
    final data = toRecord(unwrapResponse<dynamic>(res.data));
    return LearningContentModel.fromJson(toRecord(data['learning']));
  }

  Future<Map<String, dynamic>> updateRoadmapProgress(
    String roadmapId,
    String itemId,
    String status,
  ) async {
    final res = await _dio.patch(
      '/roadmaps/$roadmapId/progress/items',
      data: {'itemId': itemId, 'status': status},
    );
    return toRecord(unwrapResponse<dynamic>(res.data));
  }

  Future<Map<String, dynamic>> getRoadmapProgress(String roadmapId) async {
    final res = await _dio.get('/roadmaps/$roadmapId/progress');
    return toRecord(unwrapResponse<dynamic>(res.data));
  }

  Future<RoadmapModel> archiveRoadmap(String id) async {
    final res = await _dio.patch('/roadmaps/$id/archive');
    return normalizeRoadmap(res.data);
  }

  Future<void> deleteRoadmap(String id) async {
    await _dio.delete('/roadmaps/$id');
  }
}

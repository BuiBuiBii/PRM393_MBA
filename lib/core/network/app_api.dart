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

  Future<Map<String, dynamic>> checkServerHealth() async {
    final res = await _dio.get('/health');
    return normalizeApiHealth(res.data);
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

  Future<void> completeGitHubOAuthCallback(Map<String, String> queryParams) async {
    await _dio.get('/github/oauth/callback', queryParameters: queryParams);
  }

  Future<AnalysisModel> analyzeRepository(
    String id, {
    String view = 'detail',
    bool includeEvidence = false,
  }) async {
    await syncPackages(id);
    await syncCommits(id);
    final res = await _dio.post(
      '/analysis/repositories/$id',
      queryParameters: {
        'view': view,
        'includeEvidence': includeEvidence,
      },
    );
    return normalizeAnalysis(res.data);
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
    return RoleMatchModel.fromJson(Map<String, dynamic>.from(data as Map? ?? {}));
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
        if (targetRole != null && targetRole.isNotEmpty) 'targetRole': targetRole,
        'includeDetails': includeDetails,
      },
    );
    final data = unwrapResponse<dynamic>(res.data);
    if (data == null) return null;
    return RoleMatchModel.fromJson(Map<String, dynamic>.from(data as Map? ?? {}));
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

  Future<SnapshotCompareResultModel> compareSnapshots(String fromId, String toId) async {
    final res = await _dio.post('/snapshots/compare', data: {
      'fromSnapshotId': fromId,
      'toSnapshotId': toId,
    });
    return normalizeSnapshotCompare(res.data);
  }

  Future<SnapshotCompareResultModel> getProgressComparison(String repoId) async {
    final res = await _dio.get('/repositories/$repoId/progress-comparison');
    return normalizeSnapshotCompare(res.data);
  }

  Future<AiFeedbackModel> generateAiFeedback(String repoId) async {
    final res = await _dio.post('/ai-feedback/repositories/$repoId');
    return normalizeAiFeedback(res.data);
  }

  Future<AiFeedbackModel?> getAiFeedback(String repoId) async {
    final res = await _dio.get('/ai-feedback/results/$repoId');
    return normalizeAiFeedback(res.data);
  }

  Future<List<AiFeedbackModel>> getMyAiFeedback() async {
    final res = await _dio.get('/ai-feedback/me');
    return normalizeAiFeedbacks(res.data);
  }

  Future<Map<String, dynamic>> getGitHubOAuthUrl({required String redirectUrl}) async {
    final res = await _dio.get('/github/oauth', queryParameters: {'redirectUrl': redirectUrl});
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<Map<String, dynamic>> getGitHubAccount() async {
    final res = await _dio.get('/github/me');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<void> disconnectGitHub() async {
    await _dio.delete('/github/disconnect');
  }

  Future<List<ChatSessionModel>> getChatSessions() async {
    final res = await _dio.get('/chat/sessions');
    return normalizeChatSessions(res.data);
  }

  Future<ChatSessionModel> createChatSession(String title) async {
    final res = await _dio.post('/chat/sessions', data: {'title': title});
    return normalizeChatSession(res.data);
  }

  Future<ChatSessionModel> getChatSession(String id) async {
    final res = await _dio.get('/chat/sessions/$id');
    return normalizeChatSessionDetail(res.data);
  }

  Future<dynamic> sendChatMessage(String sessionId, String message) async {
    final res = await _dio.post('/chat/sessions/$sessionId/messages', data: {'message': message});
    return unwrapResponse(res.data);
  }

  Future<List<NotificationModel>> getNotifications({bool unreadOnly = false, String? type}) async {
    final res = await _dio.get('/notifications/me', queryParameters: {
      'page': 1,
      'limit': 20,
      if (unreadOnly) 'unreadOnly': true,
      if (type != null && type.isNotEmpty) 'type': type,
    });
    return normalizeNotifications(res.data);
  }

  Future<void> createNotification({required String title, required String message, String type = 'SYSTEM'}) async {
    await _dio.post('/notifications', data: {'title': title, 'message': message, 'type': type});
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

  Future<ProfileModel> saveProfile(ProfileModel profile, {bool exists = false}) async {
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

  Future<List<RoadmapModel>> getMyRoadmaps({String? status, String? targetRole}) async {
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

  /// @deprecated Dùng [generateRoadmap] với [RoadmapGenerateParams].
  Future<RoadmapModel> generateRoadmapLegacy({
    required String targetRole,
    String? repoId,
    String level = 'beginner',
    int durationWeeks = 6,
    String language = 'vi',
    bool forceRegenerate = false,
  }) =>
      generateRoadmap(
        RoadmapGenerateParams(
          roleId: Dev2VecRole.findByName(targetRole)?.id ?? targetRole,
          targetRole: targetRole,
          repoId: repoId,
          level: level,
          durationWeeks: durationWeeks,
          language: language,
          forceRegenerate: forceRegenerate,
        ),
      );

  Future<RoadmapModel> getRoadmap(String id) async {
    final res = await _dio.get('/roadmaps/$id');
    return normalizeRoadmap(res.data);
  }

  Future<RoadmapModel> archiveRoadmap(String id) async {
    final res = await _dio.patch('/roadmaps/$id/archive');
    return normalizeRoadmap(res.data);
  }

  Future<Map<String, dynamic>> getMyProgress() async {
    final res = await _dio.get('/progress/me');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<Map<String, dynamic>> getAiHealth() async {
    final res = await _dio.get('/ai/health');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
  }

  Future<void> submitReport({
    required String reason,
    String? targetType,
    String? targetId,
    String? description,
  }) async {
    await _dio.post('/reports', data: {
      'reason': reason,
      if (targetType != null && targetType.isNotEmpty) 'targetType': targetType,
      if (targetId != null && targetId.isNotEmpty) 'targetId': targetId,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }
}

import 'package:dio/dio.dart';

import '../../core/network/api_utils.dart';
import '../../core/network/normalizers.dart';
import '../../shared/models/app_models.dart';

class AppApi {
  AppApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> dashboardMe() async {
    final res = await _dio.get('/dashboard/me');
    return Map<String, dynamic>.from(unwrapResponse(res.data) as Map? ?? {});
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

  Future<AnalysisModel> analyzeRepository(String id) async {
    final res = await _dio.post('/analysis/repositories/$id');
    return normalizeAnalysis(res.data);
  }

  Future<AnalysisModel?> getAnalysis(String id) async {
    final res = await _dio.get('/analysis/results/$id');
    return normalizeAnalysis(res.data);
  }

  Future<List<AnalysisModel>> getMyAnalyses() async {
    final res = await _dio.get('/analysis/me');
    return normalizeAnalyses(res.data);
  }

  Future<Map<String, dynamic>> getGitHubOAuthUrl() async {
    final res = await _dio.get('/github/oauth');
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
    return normalizeChatSession(res.data);
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
    final res = await _dio.get('/profile/me');
    return normalizeProfile(res.data);
  }

  Future<ProfileModel> saveProfile(ProfileModel profile, {bool exists = false}) async {
    final res = exists
        ? await _dio.put('/profile/me', data: profile.toJson())
        : await _dio.post('/profile/me', data: profile.toJson());
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
}

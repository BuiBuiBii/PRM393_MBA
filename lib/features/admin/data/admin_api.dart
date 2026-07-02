import 'package:dio/dio.dart';

import '../../../core/network/api_utils.dart';
import '../../../shared/models/app_models.dart';
import '../models/admin_models.dart';

class AdminApi {
  AdminApi(this._dio);

  final Dio _dio;

  AdminPage<T> _parsePage<T>(dynamic payload, T Function(Map<String, dynamic>) fromJson) {
    final data = unwrapResponse<dynamic>(payload);
    if (data is! Map) {
      return AdminPage(items: const [], pagination: AdminPagination.fromJson(null));
    }
    final map = Map<String, dynamic>.from(data);
    final itemsRaw = map['items'];
    final items = itemsRaw is List
        ? itemsRaw.whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList()
        : <T>[];
    final pagination = AdminPagination.fromJson(
      map['pagination'] is Map ? Map<String, dynamic>.from(map['pagination'] as Map) : null,
    );
    return AdminPage(items: items, pagination: pagination);
  }

  Map<String, dynamic> _unwrapMap(dynamic payload) {
    final data = unwrapResponse<dynamic>(payload);
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  Future<AdminDashboardStats> getDashboard() async {
    final res = await _dio.get('/admin/dashboard');
    return AdminDashboardStats.fromJson(_unwrapMap(res.data));
  }

  Future<AdminPage<AdminUserRecord>> getUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? role,
    String? status,
  }) async {
    final res = await _dio.get('/admin/users', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (role != null && role.isNotEmpty) 'role': role,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return _parsePage(res.data, AdminUserRecord.fromJson);
  }

  Future<AdminUserRecord> getUser(String userId) async {
    final res = await _dio.get('/admin/users/$userId');
    final map = _unwrapMap(res.data);
    final user = map['user'] ?? map;
    return AdminUserRecord.fromJson(toRecord(user));
  }

  Future<AdminUserRecord> updateUserStatus(String userId, String status) async {
    final res = await _dio.patch('/admin/users/$userId/status', data: {'status': status});
    final map = _unwrapMap(res.data);
    return AdminUserRecord.fromJson(toRecord(map['user'] ?? map));
  }

  Future<AdminUserRecord> updateUserRole(String userId, String role) async {
    final res = await _dio.patch('/admin/users/$userId/role', data: {'role': role});
    final map = _unwrapMap(res.data);
    return AdminUserRecord.fromJson(toRecord(map['user'] ?? map));
  }

  Future<AdminPage<AdminReportRecord>> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? targetType,
  }) async {
    final res = await _dio.get('/admin/reports', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (targetType != null && targetType.isNotEmpty) 'targetType': targetType,
    });
    return _parsePage(res.data, AdminReportRecord.fromJson);
  }

  Future<AdminReportRecord> getReport(String reportId) async {
    final res = await _dio.get('/admin/reports/$reportId');
    final map = _unwrapMap(res.data);
    return AdminReportRecord.fromJson(toRecord(map['report'] ?? map));
  }

  Future<AdminReportRecord> updateReportStatus(
    String reportId, {
    required String status,
    String? adminNote,
  }) async {
    final res = await _dio.patch('/admin/reports/$reportId/status', data: {
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
    });
    final map = _unwrapMap(res.data);
    return AdminReportRecord.fromJson(toRecord(map['report'] ?? map));
  }

  Future<AdminPage<AdminRepoRecord>> getRepositories({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get('/admin/github/repositories', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return _parsePage(res.data, AdminRepoRecord.fromJson);
  }

  Future<AdminPage<AdminAnalysisRecord>> getAnalyses({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get('/admin/analysis', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return _parsePage(res.data, AdminAnalysisRecord.fromJson);
  }

  Future<AdminPage<AdminFeedbackRecord>> getAiFeedback({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final res = await _dio.get('/admin/ai-feedback', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return _parsePage(res.data, AdminFeedbackRecord.fromJson);
  }

  Future<AdminPage<AdminRoadmapRecord>> getRoadmaps({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final res = await _dio.get('/admin/roadmaps', queryParameters: {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    });
    return _parsePage(res.data, AdminRoadmapRecord.fromJson);
  }

  Future<AdminRoadmapRecord> getRoadmap(String roadmapId) async {
    final res = await _dio.get('/admin/roadmaps/$roadmapId');
    final map = _unwrapMap(res.data);
    return AdminRoadmapRecord.fromJson(toRecord(map['roadmap'] ?? map['item'] ?? map['detail'] ?? map));
  }

  Future<AdminRoadmapRecord> updateRoadmapStatus(String roadmapId, String status) async {
    final res = await _dio.patch('/admin/roadmaps/$roadmapId/status', data: {'status': status});
    final map = _unwrapMap(res.data);
    return AdminRoadmapRecord.fromJson(toRecord(map['roadmap'] ?? map));
  }

  Future<AdminAnalysisRecord> getAnalysis(String analysisId) async {
    final res = await _dio.get('/admin/analysis/$analysisId');
    final map = _unwrapMap(res.data);
    return AdminAnalysisRecord.fromJson(toRecord(map['analysis'] ?? map['item'] ?? map['detail'] ?? map));
  }

  Future<AdminFeedbackRecord> getAiFeedbackDetail(String feedbackId) async {
    final res = await _dio.get('/admin/ai-feedback/$feedbackId');
    final map = _unwrapMap(res.data);
    return AdminFeedbackRecord.fromJson(toRecord(map['aiFeedback'] ?? map['feedback'] ?? map['item'] ?? map['detail'] ?? map));
  }

  Future<AdminRepoRecord> getRepository(String repositoryId) async {
    final res = await _dio.get('/admin/github/repositories/$repositoryId');
    final map = _unwrapMap(res.data);
    return AdminRepoRecord.fromJson(toRecord(map['repository'] ?? map['repo'] ?? map['item'] ?? map['detail'] ?? map));
  }

  Future<ChatSettingsModel> getAdminChatSettings() async {
    final res = await _dio.get('/admin/chat/settings');
    final map = _unwrapMap(res.data);
    return ChatSettingsModel.fromJson(toRecord(map['settings'] ?? map));
  }

  Future<ChatSettingsModel> updateAdminChatSettings(String mode) async {
    final res = await _dio.patch('/admin/chat/settings', data: {'mode': mode});
    final map = _unwrapMap(res.data);
    return ChatSettingsModel.fromJson(toRecord(map['settings'] ?? map));
  }

  Future<AdminChatSessionListResponse> getAdminChatSessions({
    String? status,
    String? mode,
    String? modeSource,
    String? userId,
    String? assignedAdminId,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get('/admin/chat/sessions', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (mode != null && mode.isNotEmpty) 'mode': mode,
      if (modeSource != null && modeSource.isNotEmpty) 'modeSource': modeSource,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
      if (assignedAdminId != null && assignedAdminId.isNotEmpty) 'assignedAdminId': assignedAdminId,
      'page': page,
      'limit': limit,
    });
    return AdminChatSessionListResponse.fromJson(_unwrapMap(res.data));
  }

  Future<AdminChatSessionDetailResponse> getAdminChatSession(String sessionId) async {
    final res = await _dio.get('/admin/chat/sessions/$sessionId');
    return AdminChatSessionDetailResponse.fromJson(_unwrapMap(res.data));
  }

  Future<AdminChatSessionDetailResponse> sendAdminChatMessage({
    required String sessionId,
    required String content,
  }) async {
    final res = await _dio.post('/admin/chat/sessions/$sessionId/messages', data: {'content': content});
    return AdminChatSessionDetailResponse.fromJson(_unwrapMap(res.data));
  }

  Future<AdminChatSessionDetailResponse> updateAdminChatSessionMode({
    required String sessionId,
    required String mode,
    String? reason,
  }) async {
    final res = await _dio.patch('/admin/chat/sessions/$sessionId/mode', data: {
      'mode': mode,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
    return AdminChatSessionDetailResponse.fromJson(_unwrapMap(res.data));
  }

  Future<AdminChatSessionDetailResponse> useGlobalChatMode(String sessionId) async {
    final res = await _dio.patch('/admin/chat/sessions/$sessionId/use-global-mode');
    return AdminChatSessionDetailResponse.fromJson(_unwrapMap(res.data));
  }
}

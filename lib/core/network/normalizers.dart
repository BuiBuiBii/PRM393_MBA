import '../../core/network/api_utils.dart';
import '../../shared/models/app_models.dart';
import '../../shared/models/user_model.dart';

List<Map<String, dynamic>> asMapList(dynamic payload, [List<String> keys = const []]) {
  if (payload is List) {
    return payload.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  final unwrapped = unwrapResponse<dynamic>(payload);
  if (unwrapped is List) {
    return unwrapped.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (unwrapped is Map) {
    final map = Map<String, dynamic>.from(unwrapped);
    for (final key in keys) {
      if (map[key] is List) {
        return (map[key] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    for (final key in ['items', 'data', 'repositories', 'results', 'analyses', 'sessions', 'notifications']) {
      if (map[key] is List) {
        return (map[key] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
  }
  return [];
}

List<RepositoryModel> normalizeRepositories(dynamic payload) {
  return asMapList(payload, ['repositories', 'items']).map(RepositoryModel.fromJson).toList();
}

RepositoryModel normalizeRepository(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['repository', 'repo']);
  return RepositoryModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

List<AnalysisModel> normalizeAnalyses(dynamic payload) {
  return asMapList(payload, ['analyses', 'results', 'items']).map(AnalysisModel.fromJson).toList();
}

AnalysisModel normalizeAnalysis(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['analysis', 'result']);
  return AnalysisModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

List<ChatSessionModel> normalizeChatSessions(dynamic payload) {
  return asMapList(payload, ['sessions', 'items']).map(ChatSessionModel.fromJson).toList();
}

ChatSessionModel normalizeChatSession(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['session', 'chatSession']);
  return ChatSessionModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

ChatMessageModel normalizeChatMessage(dynamic payload) {
  return ChatMessageModel.fromJson(toRecord(payload));
}

UserModel normalizeUser(dynamic payload) {
  return UserModel.fromJson(toRecord(payload));
}

List<NotificationModel> normalizeNotifications(dynamic payload) {
  return asMapList(payload, ['notifications', 'items']).map(NotificationModel.fromJson).toList();
}

ProfileModel normalizeProfile(dynamic payload) {
  final map = extractApiResource<Map<String, dynamic>>(payload, ['profile', 'studentProfile']);
  return ProfileModel.fromJson(toRecord(map.isNotEmpty ? map : payload));
}

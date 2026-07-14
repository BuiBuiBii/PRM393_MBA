import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';

class ChatRepository {
  ChatRepository(this._api);

  final AppApi _api;

  Future<List<ChatSessionModel>> getChatSessions() => _api.getChatSessions();

  Future<ChatSessionModel> createChatSession(String title) =>
      _api.createChatSession(title);

  Future<ChatSessionModel> getChatSession(String id) => _api.getChatSession(id);

  Future<dynamic> sendChatMessage(
    String sessionId,
    String message, {
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) =>
      _api.sendChatMessage(
        sessionId,
        message,
        repositoryId: repositoryId,
        roadmapId: roadmapId,
        analysisId: analysisId,
        snapshotId: snapshotId,
      );
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(ref.read(appApiProvider)),
);

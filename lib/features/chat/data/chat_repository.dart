import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_api.dart';
import '../../../core/network/app_api_provider.dart';
import '../../../shared/models/app_models.dart';

class ChatRepository {
  ChatRepository(this._api);

  final AppApi _api;

  Future<List<ChatSessionModel>> getChatSessions() => _api.getChatSessions();

  Future<ChatSessionModel> createChatSession(
    Object payload, {
    String? repositoryId,
    String? roadmapId,
    String? analysisId,
    String? snapshotId,
  }) =>
      _api.createChatSession(
        payload,
        repositoryId: repositoryId,
        roadmapId: roadmapId,
        analysisId: analysisId,
        snapshotId: snapshotId,
      );

  Future<void> deleteChatSession(String id) => _api.deleteChatSession(id);

  Future<ChatSessionModel> getChatSession(String id) => _api.getChatSession(id);

  Future<ChatSendResult> sendChatMessage(
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

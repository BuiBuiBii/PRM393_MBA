import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/core/network/app_api.dart';
import 'package:gitanalyzer_flutter/core/network/normalizers.dart';
import 'package:gitanalyzer_flutter/features/admin/data/admin_api.dart';
import 'package:gitanalyzer_flutter/shared/models/app_models.dart';

void main() {
  test('chat detail uses senderType and effectiveMode from backend', () {
    final session = normalizeChatSessionDetail({
      'data': {
        'session': {
          '_id': 'session-1',
          'title': 'Support',
          'mode': 'MANUAL',
          'modeSource': 'SESSION',
          'effectiveMode': 'MANUAL',
          'status': 'answered',
          'unreadByUser': true,
        },
        'messages': [
          {
            '_id': 'message-user',
            'role': 'user',
            'senderType': 'USER',
            'content': 'Help me',
          },
          {
            '_id': 'message-admin',
            'role': 'assistant',
            'senderType': 'ADMIN',
            'content': 'Admin reply',
          },
        ],
      },
    });

    expect(session.effectiveMode, 'MANUAL');
    expect(session.modeSource, 'SESSION');
    expect(session.messages.last.isAdmin, isTrue);
    expect(session.messages.last.isUser, isFalse);
  });

  test('manual send response appends only the real user message', () {
    final result = normalizeChatSendResult({
      'success': true,
      'data': {
        'mode': 'MANUAL',
        'effectiveMode': 'MANUAL',
        'modeSource': 'SESSION',
        'status': 'waiting_admin',
        'userMessage': {
          '_id': 'message-1',
          'senderType': 'USER',
          'content': 'I need admin support',
        },
        'adminMessage': null,
      },
    });

    expect(result.effectiveMode, 'MANUAL');
    expect(result.status, 'waiting_admin');
    expect(result.messages, hasLength(1));
    expect(result.userMessage?.isUser, isTrue);
    expect(result.aiMessage, isNull);
  });

  test('user send API forwards context selectors and parses AI_AUTO', () async {
    late RequestOptions request;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          request = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'effectiveMode': 'AI_AUTO',
                  'mode': 'AI_AUTO',
                  'modeSource': 'GLOBAL',
                  'status': 'active',
                  'userMessage': {
                    '_id': 'user-message',
                    'senderType': 'USER',
                    'content': 'Next skill?',
                  },
                  'aiMessage': {
                    '_id': 'ai-message',
                    'senderType': 'AI',
                    'content': 'Learn testing',
                  },
                  'context': {
                    'repositoryId': 'repository-1',
                    'repoName': 'WDP_G3',
                    'roadmapId': 'roadmap-1',
                    'analysisId': 'analysis-1',
                    'snapshotId': 'snapshot-1',
                    'progressUpdatedAt': '2026-07-15T00:00:00.000Z',
                    'analysisSource': 'analysis_result',
                    'contextSelectionReason': 'body_roadmap',
                    'contextPinned': true,
                    'intent': 'ROADMAP_PROGRESS',
                    'intents': ['ROADMAP_PROGRESS'],
                    'hasRoadmapContext': true,
                    'hasComparisonContext': true,
                    'comparedRepoCount': 2,
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final result = await AppApi(dio).sendChatMessage(
      'session-1',
      'Next skill?',
      roadmapId: 'roadmap-1',
      repositoryId: 'repository-1',
      analysisId: 'analysis-1',
      snapshotId: 'snapshot-1',
    );

    expect(request.method, 'POST');
    expect(request.path, '/chat/sessions/session-1/messages');
    expect(request.data, {
      'message': 'Next skill?',
      'repositoryId': 'repository-1',
      'roadmapId': 'roadmap-1',
      'analysisId': 'analysis-1',
      'snapshotId': 'snapshot-1',
    });
    expect(result.messages, hasLength(2));
    expect(result.aiMessage?.effectiveSenderType, 'AI');
    expect(result.context?.repoName, 'WDP_G3');
    expect(result.context?.contextSelectionReason, 'body_roadmap');
    expect(result.context?.intents, ['ROADMAP_PROGRESS']);
    expect(result.context?.hasRoadmapContext, isTrue);
    expect(result.context?.hasComparisonContext, isTrue);
    expect(result.context?.comparedRepoCount, 2);
  });

  test('create session pins context and keeps legacy title calls', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {
                  'session': {
                    '_id': 'session-context',
                    'title': options.data['title'],
                    'repositoryId': options.data['repositoryId'],
                    'status': 'active',
                  },
                  'context': {
                    'repositoryId': options.data['repositoryId'],
                    'repoName': 'WDP_G3',
                    'contextSelectionReason': 'body_repository',
                    'contextPinned': true,
                  },
                },
              },
            ),
          );
        },
      ),
    );
    final api = AppApi(dio);

    final pinned = await api.createChatSession(
      const ChatSessionCreatePayload(
        title: 'Tư vấn WDP_G3',
        repositoryId: 'repository-1',
      ),
    );
    await api.createChatSession('Legacy title');

    expect(requests.first.data, {
      'title': 'Tư vấn WDP_G3',
      'repositoryId': 'repository-1',
    });
    expect(requests.last.data, {'title': 'Legacy title'});
    expect(pinned.repositoryId, 'repository-1');
    expect(pinned.context?.repoName, 'WDP_G3');
    expect(pinned.context?.contextPinned, isTrue);
  });

  test('delete chat and roadmap use DELETE endpoints', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'deleted': true}
              },
            ),
          );
        },
      ),
    );
    final api = AppApi(dio);

    await api.deleteChatSession('session-1');
    await api.deleteRoadmap('roadmap-1');

    expect(requests[0].method, 'DELETE');
    expect(requests[0].path, '/chat/sessions/session-1');
    expect(requests[1].method, 'DELETE');
    expect(requests[1].path, '/roadmaps/roadmap-1');
  });

  test('admin chat API uses documented management endpoints', () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final data = switch (options.path) {
            '/admin/chat/settings' => {
                'success': true,
                'data': {'mode': 'MANUAL'},
              },
            '/admin/chat/sessions' => {
                'success': true,
                'data': {
                  'items': <dynamic>[],
                  'pagination': {
                    'page': 1,
                    'limit': 20,
                    'total': 0,
                    'totalPages': 0,
                  },
                },
              },
            _ => {
                'success': true,
                'data': {
                  'session': {
                    '_id': 'session-1',
                    'effectiveMode': 'MANUAL',
                  },
                },
              },
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
    final api = AdminApi(dio);

    await api.getChatSettings();
    await api.getChatSessions(
      status: 'waiting_admin',
      mode: 'MANUAL',
      modeSource: 'SESSION',
    );
    await api.updateChatSessionMode(
      'session-1',
      'MANUAL',
      reason: 'Direct support',
    );
    await api.useGlobalChatMode('session-1');
    await api.sendAdminChatMessage('session-1', 'Admin reply');
    await api.closeChatSession('session-1', reason: 'Resolved');

    expect(requests[1].queryParameters, {
      'page': 1,
      'limit': 20,
      'status': 'waiting_admin',
      'mode': 'MANUAL',
      'modeSource': 'SESSION',
    });
    expect(requests[2].path, '/admin/chat/sessions/session-1/mode');
    expect(requests[2].data, {
      'mode': 'MANUAL',
      'reason': 'Direct support',
    });
    expect(
      requests[3].path,
      '/admin/chat/sessions/session-1/use-global-mode',
    );
    expect(requests[4].data, {'content': 'Admin reply'});
    expect(requests[5].path, '/admin/chat/sessions/session-1/close');
    expect(requests[5].data, {'reason': 'Resolved'});
  });
}

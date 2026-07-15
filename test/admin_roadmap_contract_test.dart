import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/features/admin/data/admin_api.dart';
import 'package:gitanalyzer_flutter/features/admin/models/admin_models.dart';

void main() {
  test('parses normalized admin roadmap summary and learning progress', () {
    final roadmap = AdminRoadmapRecord.fromJson({
      'roadmapId': 'roadmap-1',
      'title': 'Backend roadmap',
      'targetRole': 'Backend Developer',
      'status': 'active',
      'user': null,
      'repository': {
        'id': 'repo-1',
        'name': '',
        'fullName': '',
        'htmlUrl': '',
        'language': '',
      },
      'mainRoadmap': {
        'title': 'Backend roadmap',
        'phases': [],
      },
      'alternativeRoadmaps': [],
      'progressSummary': {
        'totalItems': 3,
        'completedItems': 1,
        'inProgressItems': 1,
        'pendingItems': 1,
        'overallProgress': 33,
      },
      'learningProgress': {
        'currentTask': {
          'itemId': 'task-2',
          'title': 'Build API',
          'status': 'in_progress',
          'progressPercent': 50,
        },
        'recentlyCompleted': [],
        'nextRecommendedTask': {},
        'completedTasks': [],
        'inProgressTasks': [],
        'pendingTasks': [
          {
            'itemId': 'task-3',
            'title': 'Write tests',
            'status': 'not_started',
            'progressPercent': 0,
          },
        ],
        'orphanProgressItems': [
          {
            'itemId': 'removed-task',
            'status': 'completed',
            'progressPercent': 100,
          },
        ],
        'items': [],
      },
    });

    expect(roadmap.id, 'roadmap-1');
    expect(roadmap.ownerName, 'Unknown user');
    expect(roadmap.progressSummary.pendingItems, 1);
    expect(roadmap.learningProgress?.currentTask?.itemId, 'task-2');
    expect(roadmap.learningProgress?.pendingTasks.single.status, 'not_started');
    expect(
      roadmap.learningProgress?.orphanProgressItems.single.itemId,
      'removed-task',
    );
  });

  test('admin roadmap API reads data.items, pagination and data.roadmap',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final roadmap = <String, dynamic>{
            'roadmapId': 'roadmap-1',
            'title': 'Backend roadmap',
            'targetRole': 'Backend Developer',
            'status': 'active',
            'user': null,
            'repository': null,
            'mainRoadmap': <String, dynamic>{'phases': <dynamic>[]},
            'alternativeRoadmaps': <dynamic>[],
            'progressSummary': <String, dynamic>{
              'totalItems': 2,
              'completedItems': 0,
              'inProgressItems': 0,
              'pendingItems': 2,
              'overallProgress': 0,
            },
            if (options.path.endsWith('/roadmap-1'))
              'learningProgress': <String, dynamic>{
                'currentTask': <String, dynamic>{},
                'recentlyCompleted': <dynamic>[],
                'nextRecommendedTask': <String, dynamic>{},
                'completedTasks': <dynamic>[],
                'inProgressTasks': <dynamic>[],
                'pendingTasks': <dynamic>[],
                'orphanProgressItems': <dynamic>[],
                'items': <dynamic>[],
              },
          };
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: options.path.endsWith('/roadmap-1')
                  ? {
                      'success': true,
                      'data': {'roadmap': roadmap},
                    }
                  : {
                      'success': true,
                      'data': {
                        'items': [roadmap],
                        'pagination': {
                          'page': 2,
                          'limit': 20,
                          'total': 21,
                          'totalPages': 2,
                        },
                      },
                    },
            ),
          );
        },
      ),
    );
    final api = AdminApi(dio);

    final page = await api.getRoadmaps(page: 2, includeDeleted: true);
    final detail = await api.getRoadmap('roadmap-1', includeDeleted: true);

    expect(page.items.single.progressSummary.pendingItems, 2);
    expect(page.pagination.page, 2);
    expect(page.pagination.totalPages, 2);
    expect(detail.id, 'roadmap-1');
    expect(detail.learningProgress, isNotNull);
    expect(requests[0].queryParameters['includeDeleted'], isTrue);
    expect(requests[1].queryParameters['includeDeleted'], isTrue);
  });
}

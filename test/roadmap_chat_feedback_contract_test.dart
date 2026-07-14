import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/core/network/normalizers.dart';
import 'package:gitanalyzer_flutter/shared/models/app_models.dart';

void main() {
  group('roadmap contract', () {
    test('reads generate response, provenance and exact backend itemId', () {
      final roadmap = normalizeRoadmap({
        'success': true,
        'data': {
          'roadmapId': 'roadmap-1',
          'targetRole': 'Backend Developer',
          'roadmapSource': {
            'analysisId': 'analysis-1',
            'snapshotId': 'snapshot-1',
            'repositoryId': 'repository-1',
          },
          'mainRoadmap': {
            'title': 'Backend roadmap',
            'phases': [
              {
                'title': 'API',
                'tasks': [
                  {
                    'itemId': 'main-1-1-api-testing',
                    '_id': 'mongo-subdocument-id',
                    'title': 'API Testing',
                    'estimatedHours': 5,
                  },
                ],
              },
            ],
          },
          'progressSummary': {'overallProgress': 25},
        },
      });

      expect(roadmap.id, 'roadmap-1');
      expect(roadmap.modules.single.nodes.single.id, 'main-1-1-api-testing');
      expect(roadmap.roadmapSource?['snapshotId'], 'snapshot-1');
      expect(roadmap.progress, 25);
    });

    test('does not synthesize itemId from an array index', () {
      final roadmap = normalizeRoadmap({
        'data': {
          'roadmapId': 'roadmap-1',
          'targetRole': 'Backend Developer',
          'mainRoadmap': {
            'phases': [
              {
                'tasks': [
                  {
                    'id': 'task-id-must-not-be-used',
                    '_id': 'mongo-id-must-not-be-used',
                    'title': 'Legacy invalid task',
                  },
                ],
              },
            ],
          },
        },
      });

      expect(roadmap.modules.single.nodes.single.id, isEmpty);
    });
  });

  test(
      'learning content reads only public contract fields and accepts empty resources',
      () {
    final learning = LearningContentModel.fromJson({
      'title': 'API Testing',
      'overview': 'Overview',
      'whyLearn': 'Why',
      'useCases': ['Contract tests'],
      'resources': [],
      'summary': 'must not replace overview',
    });

    expect(learning.overview, 'Overview');
    expect(learning.useCases, ['Contract tests']);
    expect(learning.resources, isEmpty);
  });

  test('analysis and feedback keep real snapshot/provenance fields', () {
    final analysis = AnalysisModel.fromJson({
      'analysisId': 'analysis-1',
      'snapshotId': 'snapshot-1',
    });
    final feedback = AiFeedbackModel.fromJson({
      '_id': 'feedback-1',
      'repositoryId': 'repository-1',
      'analysisId': 'analysis-1',
      'snapshotId': 'snapshot-1',
      'roadmapId': 'roadmap-1',
      'isStale': true,
    });

    expect(analysis.id, 'analysis-1');
    expect(analysis.snapshotId, 'snapshot-1');
    expect(feedback.snapshotId, 'snapshot-1');
    expect(feedback.roadmapId, 'roadmap-1');
    expect(feedback.isStale, isTrue);
  });
}

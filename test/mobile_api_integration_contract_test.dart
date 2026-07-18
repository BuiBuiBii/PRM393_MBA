import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/core/network/normalizers.dart';
import 'package:gitanalyzer_flutter/features/admin/models/admin_models.dart';
import 'package:gitanalyzer_flutter/features/roadmaps/utils/roadmap_progress_utils.dart';

void main() {
  test('roadmap progress uses backend summary and merges statuses by itemId',
      () {
    final roadmap = normalizeRoadmap({
      'data': {
        'roadmap': {
          'roadmapId': 'roadmap-1',
          'targetRole': 'Backend Developer',
          'mainRoadmap': {
            'title': 'Backend path',
            'phases': [
              {
                'title': 'Phase 1',
                'tasks': [
                  {
                    'itemId': 'task-1',
                    'title': 'Build API',
                    'status': 'not_started',
                  },
                  {
                    'itemId': 'task-2',
                    'title': 'Write tests',
                    'status': 'not_started',
                  },
                ],
              },
            ],
          },
        },
      },
    });

    final merged = mergeRoadmapProgress(roadmap, {
      'progressSummary': {
        'totalItems': 2,
        'completedItems': 1,
        'inProgressItems': 1,
        'overallProgress': 50,
      },
      'items': [
        {'itemId': 'task-1', 'status': 'completed'},
        {'itemId': 'task-2', 'status': 'in_progress'},
      ],
    });

    expect(merged.progress, 50);
    expect(merged.modules.single.nodes[0].status, 'completed');
    expect(merged.modules.single.nodes[1].status, 'in-progress');
    expect(merged.progressSummary?['overallProgress'], 50);
  });

  test(
      'admin raw analysis reads repository and maps missing skills from skillSignals',
      () {
    final analysis = AdminAnalysisRecord.fromJson({
      '_id': 'analysis-1',
      'userId': {
        '_id': 'user-1',
        'fullName': 'Student Name',
        'email': 'student@example.com',
      },
      'repositoryId': {
        '_id': 'repo-1',
        'name': 'WDP_G3',
        'fullName': 'owner/WDP_G3',
      },
      'projectType': 'Backend',
      'careerDirection': 'Backend Developer',
      'missingSkills': ['Legacy field is ignored'],
      'skillSignals': ['API Testing'],
      'analysisScope': {
        'type': 'user_contribution',
        'githubUsername': 'student',
        'userCommits': 12,
        'totalRepoCommits': 40,
        'activeDays': 5,
      },
      'strengths': ['Clear API structure'],
      'scores': {'overallScore': 61.4},
    });

    expect(analysis.id, 'analysis-1');
    expect(analysis.repoName, 'WDP_G3');
    expect(analysis.ownerName, 'Student Name');
    expect(analysis.missingSkills, ['API Testing']);
    expect(analysis.analysisScope['githubUsername'], 'student');
    expect(analysis.analysisScope['userCommits'], 12);
    expect(analysis.overallScore, 61);
  });
}

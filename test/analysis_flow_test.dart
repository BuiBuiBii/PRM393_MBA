import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/core/network/app_api.dart';
import 'package:gitanalyzer_flutter/core/network/normalizers.dart';

void main() {
  test('analysis calls POST directly and keeps repository id from request path',
      () async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 201,
              data: {
                'success': true,
                'data': {
                  'analysisId': 'analysis-1',
                  'snapshotId': 'snapshot-1',
                  'analysisResult': {
                    'userLevel': 'intermediate',
                    'scores': {
                      'architectureScore': 72.5,
                      'completenessScore': '81.4',
                      'commitQualityScore': 66.6,
                      'documentationScore': 54.2,
                      'codeQualityScore': 77.7,
                      'overallScore': 70.48,
                    },
                    'scoreBreakdown': {
                      'technical': 0.82,
                      'portfolio': 0.64,
                    },
                  },
                },
              },
            ),
          );
        },
      ),
    );

    final analysis = await AppApi(dio).analyzeRepository('repository-1');

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(requests.single.path, '/analysis/repositories/repository-1');
    expect(requests.single.queryParameters, {
      'view': 'detail',
      'includeEvidence': false,
    });
    expect(requests.single.receiveTimeout, const Duration(minutes: 3));
    expect(analysis.id, 'analysis-1');
    expect(analysis.snapshotId, 'snapshot-1');
    expect(analysis.repositoryId, 'repository-1');
    expect(analysis.scores.architecture, 73);
    expect(analysis.scores.completeness, 81);
    expect(analysis.scores.commitQuality, 67);
    expect(analysis.scores.documentation, 54);
    expect(analysis.scores.codeConvention, 78);
    expect(analysis.scores.overall, 70);
    expect(analysis.scoreBreakdown, {'technical': 82, 'portfolio': 64});
  });

  test('analysis score parser converts a normalized 0..1 score set to percent',
      () {
    final analysis = normalizeAnalysis({
      'data': {
        'analysisResult': {
          'scores': {
            'architecture': 0.75,
            'completeness': 0.8,
            'commitQuality': 0.65,
            'documentation': 0.5,
            'codeConvention': 0.9,
            'overall': 0.72,
          },
        },
      },
    });

    expect(analysis.scores.architecture, 75);
    expect(analysis.scores.overall, 72);
  });

  test('analysis parses summary, repository, scope and skill objects', () {
    final analysis = normalizeAnalysis({
      'success': true,
      'data': {
        'analysisId': 'analysis-real',
        'snapshotId': 'snapshot-real',
        'repository': {
          'repositoryId': 'repository-real',
          'githubRepoId': 1250613605,
          'repoName': 'WDP_G3',
          'fullName': 'ToanLkt/WDP_G3',
        },
        'analysisScope': {
          'type': 'user_contribution',
          'githubUsername': 'ToanLkt',
          'totalRepoCommits': 66,
          'userCommits': 43,
          'activeDays': 14,
          'firstCommitDate': '2026-05-26T20:04:40.000Z',
          'lastCommitDate': '2026-07-07T08:13:41.000Z',
        },
        'summary': {
          'careerDirection': 'Backend Developer',
          'userLevel': 'beginner',
          'userReadinessScore': 67.6,
          'overallScore': 67.6,
          'projectType': 'Backend',
          'confidence': 0.675977,
        },
        'topSkills': [
          {
            'skill': 'Database',
            'canonicalSkillName': 'Database',
            'category': 'backend',
            'score': 17.76,
            'level': 'weak',
          },
        ],
        'missingSkills': [],
        'strengths': ['Analyzed 43 commits.'],
        'weaknesses': ['Low similarity.'],
        'recommendations': ['Add tests.'],
        'createdAt': '2026-07-14T15:47:25.580Z',
      },
    });

    expect(analysis.id, 'analysis-real');
    expect(analysis.snapshotId, 'snapshot-real');
    expect(analysis.repositoryId, 'repository-real');
    expect(analysis.repositoryName, 'ToanLkt/WDP_G3');
    expect(analysis.githubRepoId, 1250613605);
    expect(analysis.scores.overall, 68);
    expect(analysis.scores.hasDetails, isFalse);
    expect(analysis.userReadinessScore, 68);
    expect(analysis.careerDirection, 'Backend Developer');
    expect(analysis.projectType, 'Backend');
    expect(analysis.topSkills, ['Database']);
    expect(analysis.topSkillDetails.single.score, 17.76);
    expect(analysis.analysisScope?.githubUsername, 'ToanLkt');
    expect(analysis.analysisScope?.userCommits, 43);
    expect(analysis.analysisScope?.totalRepoCommits, 66);
    expect(analysis.strengths, ['Analyzed 43 commits.']);
    expect(analysis.weaknesses, ['Low similarity.']);
    expect(analysis.recommendations, ['Add tests.']);
    expect(analysis.hasCompleteNarrative, isTrue);
  });

  test('analysis keeps narrative fields placed beside analysisResult', () {
    final analysis = normalizeAnalysis({
      'data': {
        'analysisId': 'analysis-with-envelope-content',
        'analysisResult': {
          'summary': {'overallScore': 70},
        },
        'strengths': ['Clear project evidence.'],
        'weaknesses': ['Tests need improvement.'],
        'recommendations': ['Add integration tests.'],
      },
    });

    expect(analysis.strengths, ['Clear project evidence.']);
    expect(analysis.weaknesses, ['Tests need improvement.']);
    expect(analysis.recommendations, ['Add integration tests.']);
  });
}

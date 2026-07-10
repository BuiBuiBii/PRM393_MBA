import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/shared/models/app_models.dart';

void main() {
  group('RoleMatchItem.fromJson', () {
    test('parses Dev2Vec payload with roleId and skill name fields', () {
      final item = RoleMatchItem.fromJson({
        'roleId': 'backend',
        'roleName': 'Backend Developer',
        'matchScore': 78.5,
        'matchLevelLabel': 'Moderate',
        'matchedSkillNames': ['Node.js', 'Express'],
        'missingSkillNames': ['Docker'],
        'recommendedNextSkills': ['CI/CD'],
        'scoringMethod': 'dev2vec',
      });

      expect(item.roleId, 'backend');
      expect(item.role, 'Backend Developer');
      expect(item.matchScore, 78.5);
      expect(item.matchedSkills, ['Node.js', 'Express']);
      expect(item.missingSkills, ['Docker']);
      expect(item.recommendedNextSkills, ['CI/CD']);
      expect(item.scoringMethod, 'dev2vec');
    });
  });

  group('RoleMatchModel.fromJson', () {
    test('parses matches array capped by BE', () {
      final model = RoleMatchModel.fromJson({
        'topRole': 'Backend Developer',
        'analysisSource': 'dev2vec',
        'matches': [
          {'roleId': 'backend', 'roleName': 'Backend Developer', 'matchScore': 80},
          {'roleId': 'frontend', 'roleName': 'Frontend Developer', 'matchScore': 55},
        ],
      });

      expect(model.matches.length, 2);
      expect(model.topRole, 'Backend Developer');
      expect(model.analysisSource, 'dev2vec');
      expect(model.topMatch?.roleId, 'backend');
    });
  });
}

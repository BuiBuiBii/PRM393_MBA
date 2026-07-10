import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/shared/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromJson parses core fields', () {
      final user = UserModel.fromJson({
        'id': 'u1',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'role': 'student',
        'provider': 'email',
      });

      expect(user.id, 'u1');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, 'student');
    });

    test('mergeMissingFrom keeps existing values', () {
      final base = UserModel.fromJson({'id': '1', 'email': 'a@b.com', 'fullName': 'A'});
      final merged = base.mergeMissingFrom(UserModel.fromJson({'fullName': 'B', 'githubUsername': 'dev'}));

      expect(merged.name, 'A');
      expect(merged.githubUsername, 'dev');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gitanalyzer_flutter/core/auth/oauth_callback_utils.dart';

void main() {
  group('appTokenFromCallbackUri', () {
    test('reads token from backend query callback', () {
      final uri = Uri.parse(
        'gitanalyzer://auth/github/callback?token=app-jwt&success=true',
      );

      expect(appTokenFromCallbackUri(uri), 'app-jwt');
    });

    test('reads accessToken from fragment callback', () {
      final uri = Uri.parse(
        'gitanalyzer://auth/github/callback#accessToken=app-jwt',
      );

      expect(appTokenFromCallbackUri(uri), 'app-jwt');
    });

    test('prefers fragment token when both formats are present', () {
      final uri = Uri.parse(
        'gitanalyzer://auth/github/callback?token=query-jwt'
        '#accessToken=fragment-jwt',
      );

      expect(appTokenFromCallbackUri(uri), 'fragment-jwt');
    });
  });
}

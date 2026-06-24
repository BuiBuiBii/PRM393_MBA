import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../network/api_utils.dart';
import 'github_oauth_service.dart';

String mapGoogleSignInError(Object error) {
  if (error is ApiException) return error.message;

  if (error is PlatformException) {
    final message = error.message ?? error.code;
    if (message.contains('10') || message.contains('ApiException: 10')) {
      return 'Google Sign-In lỗi cấu hình (ApiException: 10). '
          'Thêm SHA-1 debug vào Google Cloud Console cho package com.gitanalyzer.app.gitanalyzer_flutter.';
    }
    if (error.code == 'sign_in_canceled') {
      return 'Đăng nhập Google đã hủy';
    }
    return 'Đăng nhập Google thất bại: $message';
  }

  return getApiErrorMessage(error);
}

enum GithubSignInMode { appToken, accessToken }

class GithubSignInResult {
  const GithubSignInResult._(this.mode, this.value);

  final GithubSignInMode mode;
  final String value;

  factory GithubSignInResult.appToken(String token) =>
      GithubSignInResult._(GithubSignInMode.appToken, token);

  factory GithubSignInResult.accessToken(String token) =>
      GithubSignInResult._(GithubSignInMode.accessToken, token);
}

class SocialAuthService {
  SocialAuthService({GithubOAuthService? githubOAuth})
      : _githubOAuth = githubOAuth ?? GithubOAuthService();

  final GithubOAuthService _githubOAuth;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: kIsWeb && AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
    serverClientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
  );

  Future<String> signInWithGoogle() async {
    if (AppConfig.googleClientId.isEmpty) {
      throw ApiException('Chưa cấu hình GOOGLE_CLIENT_ID. Chạy app với --dart-define=GOOGLE_CLIENT_ID=...');
    }

    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw ApiException('Đăng nhập Google đã hủy');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw ApiException(
          'Không lấy được Google idToken. Kiểm tra GOOGLE_CLIENT_ID khớp BE và SHA-1 Android trên Google Cloud.',
        );
      }

      return idToken;
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(mapGoogleSignInError(error));
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  /// GitHub login: BE OAuth → deep link JWT (khớp Web, không cần client secret trong app).
  Future<GithubSignInResult> signInWithGithub() async {
    final appJwt = await _githubOAuth.signInForAppJwt();
    return GithubSignInResult.appToken(appJwt);
  }
}

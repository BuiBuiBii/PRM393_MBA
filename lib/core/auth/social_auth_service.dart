import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../network/api_utils.dart';

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
  SocialAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    // Web requires clientId (meta tag or constructor); mobile uses serverClientId for idToken.
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

  Future<GithubSignInResult> signInWithGithub() async {
    if (AppConfig.useBackendGithubLogin) {
      return _signInWithGithubViaBackend();
    }
    return GithubSignInResult.accessToken(await _signInWithGithubDirect());
  }

  Future<GithubSignInResult> _signInWithGithubViaBackend() async {
    final redirectUri = AppConfig.githubAuthRedirectUri;
    final api = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

    final authorizeResponse = await api.post<Map<String, dynamic>>(
      '/auth/github',
      data: {'redirectUrl': redirectUri},
    );

    final payload = unwrapResponse<dynamic>(authorizeResponse.data);
    final authorizeUrl = payload is Map 
        ? (payload['authorizeUrl'] ?? payload['authorizationUrl'] ?? payload['oauthUrl'] ?? payload['url'])?.toString() 
        : null;
    if (authorizeUrl == null || authorizeUrl.isEmpty) {
      throw ApiException('BE không trả về GitHub authorize URL. Kiểm tra GITHUB_CLIENT_ID trên server.');
    }

    final result = await FlutterWebAuth2.authenticate(
      url: authorizeUrl,
      callbackUrlScheme: Uri.parse(redirectUri).scheme,
    );

    final callback = Uri.parse(result);
    final fragmentParams = Uri.splitQueryString(callback.fragment);

    final error = fragmentParams['error'] ?? callback.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      throw ApiException(error);
    }

    final token = fragmentParams['accessToken'] ?? fragmentParams['token'] ?? callback.queryParameters['token'];
    if (token == null || token.isEmpty) {
      throw ApiException('GitHub OAuth không trả về token đăng nhập');
    }

    return GithubSignInResult.appToken(token);
  }

  Future<String> _signInWithGithubDirect() async {
    if (AppConfig.githubClientId.isEmpty || AppConfig.githubClientSecret.isEmpty) {
      throw ApiException(
        'Chưa cấu hình GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET. '
        'Mặc định app dùng OAuth qua BE — kiểm tra API_BASE_URL và BE env.',
      );
    }

    final redirectUri = AppConfig.githubAuthRedirectUri;
    final authUrl = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': AppConfig.githubClientId,
      'redirect_uri': redirectUri,
      'scope': 'read:user user:email',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: Uri.parse(redirectUri).scheme,
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw ApiException('GitHub OAuth không trả về mã xác thực');
    }

    final tokenResponse = await _dio.post<Map<String, dynamic>>(
      'https://github.com/login/oauth/access_token',
      data: {
        'client_id': AppConfig.githubClientId,
        'client_secret': AppConfig.githubClientSecret,
        'code': code,
        'redirect_uri': redirectUri,
      },
      options: Options(
        headers: {'Accept': 'application/json'},
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
      ),
    );

    final accessToken = tokenResponse.data?['access_token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      final err = tokenResponse.data?['error_description'] ?? tokenResponse.data?['error'];
      throw ApiException(err?.toString() ?? 'Không đổi được GitHub access token');
    }

    return accessToken;
  }
}

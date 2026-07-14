import 'package:dio/dio.dart';

import 'package:flutter/services.dart';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../config/app_config.dart';

import '../network/api_utils.dart';

import 'oauth_callback_utils.dart';

/// GitHub OAuth mobile — khớp spec BE:

///

/// Login: `POST /auth/github { redirectUrl }` → authUrl → browser ngoài →

///        `gitanalyzer://auth/github/callback#accessToken=JWT`

/// Connect: `GET /github/oauth?redirectUrl=<encoded>` + Bearer → deep link → `GET /github/account`

class GithubOAuthService {
  GithubOAuthService({Dio? apiDio})
      : _apiDio = apiDio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _apiDio;

  /// Trả JWT app (từ fragment `#accessToken` của deep link).

  Future<String> signInForAppJwt() async {
    final redirectUri = AppConfig.githubAuthRedirectUri;

    final authorizeUrl = await _fetchLoginAuthorizeUrl(redirectUri);

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorizeUrl,
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );

      final callback = Uri.parse(result);

      final error = oauthErrorFromUri(callback);

      if (error != null) throw ApiException(error);

      final token = appAccessTokenFromFragment(callback);

      if (token == null || token.isEmpty) {
        throw ApiException(
          'Thiếu #accessToken trong callback GitHub. '
          'BE phải redirect về $redirectUri#accessToken=...',
        );
      }

      return token;
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED' || e.code == 'cancelled') {
        throw ApiException(
          'Không nhận được callback từ GitHub. Rebuild app (flutter clean && flutter run) rồi thử lại.',
        );
      }

      throw ApiException(e.message ?? 'Đăng nhập GitHub thất bại');
    }
  }

  Future<String> _fetchLoginAuthorizeUrl(String redirectUri) async {
    try {
      final postRes = await _apiDio.post<dynamic>('/auth/github', data: {
        'redirectUrl': redirectUri,
      });

      final fromPost = extractOAuthAuthorizeUrl(postRes.data);

      if (fromPost != null && fromPost.isNotEmpty) {
        return _toAbsoluteOAuthUrl(fromPost);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      if (status != null && status != 404 && status != 405) {
        throw ApiException(getApiErrorMessage(e));
      }
    }

    try {
      final getRes = await _apiDio.get<dynamic>(
        '/auth/github/authorize',
        queryParameters: {'redirectUrl': redirectUri},
      );

      final fromGet = extractOAuthAuthorizeUrl(getRes.data);

      if (fromGet != null && fromGet.isNotEmpty) {
        return _toAbsoluteOAuthUrl(fromGet);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw ApiException(
            'API không hỗ trợ POST /auth/github cho đăng nhập GitHub.');
      }

      throw ApiException(getApiErrorMessage(e));
    }

    throw ApiException('Backend không trả authUrl cho đăng nhập GitHub');
  }

  Future<void> connectWithJwt(
    Dio authenticatedDio, {
    bool forceAccountSelection = false,
  }) async {
    final redirectUri = AppConfig.githubConnectRedirectUri;

    // Dio tự URL-encode query value → redirectUrl=gitanalyzer%3A%2F%2Fgithub%2Fconnect

    final res = await authenticatedDio.get<Map<String, dynamic>>(
      '/github/oauth',
      queryParameters: {
        'redirectUrl': redirectUri,
        if (forceAccountSelection) 'forceAccountSelection': true,
      },
    );

    final payload = unwrapResponse<dynamic>(res.data);

    final rawUrl =
        extractOAuthAuthorizeUrl(payload) ?? extractOAuthAuthorizeUrl(res.data);

    if (rawUrl == null || rawUrl.isEmpty) {
      throw ApiException('Backend không trả authorizeUrl');
    }

    final authorizeUrl = _toAbsoluteOAuthUrl(rawUrl);

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authorizeUrl,
        callbackUrlScheme: Uri.parse(redirectUri).scheme,
      );

      final error = oauthErrorFromUri(Uri.parse(result));

      if (error != null) throw ApiException(error);
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED' || e.code == 'cancelled') {
        throw ApiException('Không nhận được callback kết nối GitHub.');
      }

      throw ApiException(e.message ?? 'Kết nối GitHub thất bại');
    }

    final meRes = await authenticatedDio.get<dynamic>('/github/account');

    final account = extractApiResource<dynamic>(
      unwrapResponse<dynamic>(meRes.data),
      ['githubAccount', 'github', 'account'],
    );

    if (account is! Map || account.isEmpty) {
      throw ApiException(
          'Kết nối GitHub chưa xác nhận được — GET /github/account trống');
    }
  }

  String _toAbsoluteOAuthUrl(String url) {
    if (url.startsWith('http')) return url;

    return Uri.parse(AppConfig.apiBaseUrl).resolve(url).toString();
  }
}

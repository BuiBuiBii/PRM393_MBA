import 'package:dio/dio.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../network/api_utils.dart';

class SocialAuthService {
  SocialAuthService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: AppConfig.googleClientId.isNotEmpty ? AppConfig.googleClientId : null,
  );

  Future<String> signInWithGoogle() async {
    if (AppConfig.googleClientId.isEmpty) {
      throw ApiException('Chưa cấu hình GOOGLE_CLIENT_ID. Chạy app với --dart-define=GOOGLE_CLIENT_ID=...');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw ApiException('Đăng nhập Google đã hủy');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        'Không lấy được Google idToken. Kiểm tra GOOGLE_CLIENT_ID khớp với BE.',
      );
    }

    return idToken;
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  Future<String> signInWithGithub() async {
    if (AppConfig.githubClientId.isEmpty || AppConfig.githubClientSecret.isEmpty) {
      throw ApiException(
        'Chưa cấu hình GITHUB_CLIENT_ID / GITHUB_CLIENT_SECRET. '
        'Thêm dart-define khi build hoặc dùng đăng nhập email.',
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
      final error = tokenResponse.data?['error_description'] ?? tokenResponse.data?['error'];
      throw ApiException(error?.toString() ?? 'Không đổi được GitHub access token');
    }

    return accessToken;
  }
}

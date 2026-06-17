import 'package:dio/dio.dart';

import '../../../core/network/api_utils.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user_model.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'password': password,
      'fullName': fullName,
    });
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }

  Future<Map<String, dynamic>> loginWithGoogle({required String idToken}) async {
    final response = await _dio.post('/auth/google', data: {'idToken': idToken});
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }

  Future<Map<String, dynamic>> loginWithGithub({required String accessToken}) async {
    final response = await _dio.post('/auth/github', data: {'accessToken': accessToken});
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<Map<String, dynamic>> me() async {
    final response = await _dio.get('/auth/me');
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    });
    return unwrapResponse<Map<String, dynamic>>(response.data);
  }
}

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorageReader storage,
  })  : _api = api,
        storage = storage;

  final AuthApi _api;
  final TokenStorageReader storage;

  Future<UserModel> login(String email, String password) async {
    final payload = await _api.login(email: email, password: password);
    await _persistSession(payload, fallbackEmail: email);
    return _loadCurrentUser();
  }

  Future<UserModel> register(String email, String password, String fullName) async {
    final payload = await _api.register(
      email: email,
      password: password,
      fullName: fullName,
    );
    await _persistSession(payload, fallbackEmail: email, fallbackName: fullName);
    return _loadCurrentUser();
  }

  Future<UserModel> loginWithGoogle(String idToken) async {
    final payload = await _api.loginWithGoogle(idToken: idToken);
    await _persistSession(payload);
    return _userFromPayloadOrMe(payload);
  }

  Future<UserModel> loginWithGithub(String accessToken) async {
    final payload = await _api.loginWithGithub(accessToken: accessToken);
    await _persistSession(payload);
    return _userFromPayloadOrMe(payload);
  }

  Future<UserModel> completeSocialLoginWithToken(String token) async {
    await storage.saveToken(token);
    return _loadCurrentUser();
  }

  Future<UserModel?> bootstrap() async {
    final token = await storage.getToken();
    if (token == null || token.isEmpty) return null;

    final payload = await _api.me();
    final userPayload = extractApiResource<Map<String, dynamic>>(
      payload,
      ['user', 'account', 'profile'],
    );
    var user = UserModel.fromJson(toRecord(userPayload));
    user = await _mergeWithCachedUser(user);
    await storage.saveUser(user.toJson());
    return user;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } finally {
      await storage.clear();
    }
  }

  Future<UserModel> _userFromPayloadOrMe(Map<String, dynamic> payload) async {
    final userPayload = extractApiResource<Map<String, dynamic>>(
      payload,
      ['user', 'account', 'profile'],
    );
    final record = toRecord(userPayload);
    if (record.isNotEmpty) {
      var user = UserModel.fromJson(record);
      user = await _mergeWithCachedUser(user);
      await storage.saveUser(user.toJson());
      return user;
    }
    return _loadCurrentUser();
  }

  Future<UserModel> _loadCurrentUser() async {
    final payload = await _api.me();
    final userPayload = extractApiResource<Map<String, dynamic>>(
      payload,
      ['user', 'account', 'profile'],
    );
    var user = UserModel.fromJson(toRecord(userPayload));
    user = await _mergeWithCachedUser(user);
    await storage.saveUser(user.toJson());
    return user;
  }

  Future<UserModel> _mergeWithCachedUser(UserModel user) async {
    final cached = await storage.getUser();
    if (cached == null) return user;
    return user.mergeMissingFrom(UserModel.fromJson(cached));
  }

  Future<void> _persistSession(
    Map<String, dynamic> payload, {
    String? fallbackEmail,
    String? fallbackName,
  }) async {
    final token = findToken(payload);
    if (token != null) {
      await storage.saveToken(token);
    }

    final userPayload = extractApiResource<Map<String, dynamic>>(
      payload,
      ['user', 'account', 'profile'],
    );
    final record = toRecord(userPayload);
    if (fallbackEmail != null && record['email'] == null) {
      record['email'] = fallbackEmail;
    }
    if (fallbackName != null && record['fullName'] == null) {
      record['fullName'] = fallbackName;
    }

    if (record.isNotEmpty) {
      await storage.saveUser(UserModel.fromJson(record).toJson());
    }
  }
}

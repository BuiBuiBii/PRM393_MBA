import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

abstract class TokenStorageReader {
  Future<String?> getToken();
  Future<Map<String, dynamic>?> getUser();
  Future<void> saveToken(String token);
  Future<void> saveUser(Map<String, dynamic> user);
  Future<void> clear();
}

class TokenStorage implements TokenStorageReader {
  TokenStorage(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<String?> getToken() async => _prefs.getString(AppConfig.tokenKey);

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(AppConfig.tokenKey);
  }

  @override
  Future<Map<String, dynamic>?> getUser() async {
    final raw = _prefs.getString(AppConfig.userKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {
      await _prefs.remove(AppConfig.userKey);
    }
    return null;
  }

  @override
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString(AppConfig.userKey, jsonEncode(user));
  }

  Future<void> clearUser() async {
    await _prefs.remove(AppConfig.userKey);
  }

  @override
  Future<void> clear() async {
    await clearToken();
    await clearUser();
  }
}

Future<TokenStorage> createTokenStorage() async {
  final prefs = await SharedPreferences.getInstance();
  return TokenStorage(prefs);
}

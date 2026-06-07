import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

String getApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return error.message ?? 'Đã có lỗi xảy ra';
  }

  if (error is ApiException) return error.message;
  return error.toString();
}

T unwrapResponse<T>(dynamic payload) {
  if (payload is Map<String, dynamic>) {
    if (payload.containsKey('data')) {
      return payload['data'] as T;
    }
    if (payload.containsKey('result')) {
      return payload['result'] as T;
    }
  }
  return payload as T;
}

T extractApiResource<T>(dynamic payload, List<String> keys) {
  final unwrapped = unwrapResponse<dynamic>(payload);
  if (unwrapped is Map<String, dynamic>) {
    for (final key in keys) {
      if (unwrapped.containsKey(key)) {
        return unwrapped[key] as T;
      }
    }
  }
  return unwrapped as T;
}

String? findToken(dynamic payload) {
  if (payload is! Map) return null;

  for (final key in ['token', 'accessToken', 'access_token', 'jwt', 'jwtToken']) {
    final value = payload[key];
    if (value is String && value.isNotEmpty) return value;
  }

  for (final nested in ['data', 'result', 'user']) {
    final token = findToken(payload[nested]);
    if (token != null) return token;
  }

  return null;
}

Map<String, dynamic> toRecord(dynamic payload) {
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) {
    return payload.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

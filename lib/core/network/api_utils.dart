import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

const _dev2VecErrorMessages = <String, String>{
  'DEV2VEC_MODEL_UNAVAILABLE':
      'Hệ thống phân tích role (Dev2Vec) tạm thời không khả dụng. Vui lòng thử lại sau.',
  'DEV2VEC_INFERENCE_FAILED':
      'Không thể phân tích role phù hợp lúc này. Vui lòng thử lại sau.',
  'DEV2VEC_INVALID_OUTPUT':
      'Kết quả phân tích role không hợp lệ. Vui lòng phân tích lại repository.',
  'DEV2VEC_ANALYSIS_REQUIRED':
      'Vui lòng phân tích repository trước khi xem gợi ý role hoặc tạo roadmap.',
};

String? _extractErrorCode(Map data) {
  final code = data['code'] ?? data['errorCode'];
  if (code != null) return code.toString();
  final nested = data['error'];
  if (nested is Map) {
    final nestedCode = nested['code'] ?? nested['errorCode'];
    if (nestedCode != null) return nestedCode.toString();
  }
  return null;
}

String _mapDev2VecMessage(String? code, String? fallback) {
  if (code != null && _dev2VecErrorMessages.containsKey(code)) {
    return _dev2VecErrorMessages[code]!;
  }
  return fallback ?? 'Đã có lỗi xảy ra';
}

String getApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = _extractErrorCode(Map<String, dynamic>.from(data));
      final message = data['message'] ?? data['error'];
      final fallback = message is Map ? message['message']?.toString() : message?.toString();
      return _mapDev2VecMessage(code, fallback);
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

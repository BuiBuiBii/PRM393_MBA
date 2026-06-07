import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_utils.dart';

typedef UnauthorizedHandler = void Function();

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('TokenStorage chua duoc khoi tao');
});

final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>((ref) {
  return () {};
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final onUnauthorized = ref.watch(unauthorizedHandlerProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await tokenStorage.clear();
          onUnauthorized();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

Future<T> safeRequest<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (error) {
    throw ApiException(getApiErrorMessage(error), statusCode: error.response?.statusCode);
  }
}

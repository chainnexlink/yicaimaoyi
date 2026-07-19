import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/token_refresh_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Dio HTTP 客户端工厂
class DioClient {
  DioClient._();

  static Dio create({
    required SecureStorageService secureStorage,
    void Function()? onLogout,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: AppConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: AppConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 拦截器链：顺序重要
    // 请求方向: Logging → Auth → [服务器]
    // 响应方向: [服务器] → TokenRefresh → Error → Logging
    dio.interceptors.addAll([
      LoggingInterceptor(),
      AuthInterceptor(secureStorage),
      TokenRefreshInterceptor(dio, secureStorage, onLogout: onLogout),
      ErrorInterceptor(),
    ]);

    return dio;
  }
}

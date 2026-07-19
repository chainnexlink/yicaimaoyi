import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../storage/secure_storage.dart';

/// Auth 拦截器 - 自动注入 Bearer Token
///
/// 注意：onRequest 中 await 读取 SecureStorage，
/// 必须用 try-catch 包裹，否则异常会导致 handler 永不完成、请求永久挂起。
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final path = options.path;

      // 公开接口不需要 Token
      if (ApiConstants.isPublicPath(path)) {
        handler.next(options);
        return;
      }

      // 从安全存储获取 Token
      final token = await _storage.read(StorageKeys.accessToken);
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e) {
      // 即使读取 token 失败，也必须让请求继续（无 token），
      // 否则 handler 永不完成，请求会永久挂起
      handler.next(options);
    }
  }
}

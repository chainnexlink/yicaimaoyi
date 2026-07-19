import 'dart:async';
import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../storage/secure_storage.dart';

/// Token 刷新拦截器 - 401 时自动刷新 Token 并重放请求
/// 使用 Completer 队列锁防止并发刷新
///
/// 注意：整个 onError 用顶层 try-catch 包裹，
/// 确保 handler 在任何异常路径下都被调用，避免请求永久挂起。
class TokenRefreshInterceptor extends Interceptor {
  final Dio _dio;
  final SecureStorageService _storage;
  final void Function()? onLogout;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _queue = [];

  TokenRefreshInterceptor(this._dio, this._storage, {this.onLogout});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    try {
      final statusCode = err.response?.statusCode;
      if (statusCode != 401 && statusCode != 403) {
        handler.next(err);
        return;
      }

      // 刷新 Token 接口本身 401，直接退出登录
      if (err.requestOptions.path == ApiConstants.authRefresh) {
        await _clearTokensSafe();
        handler.next(err);
        return;
      }

      // 如果正在刷新中，将请求加入等待队列
      if (_isRefreshing) {
        final completer = Completer<Response>();
        _queue.add(_QueuedRequest(err.requestOptions, completer));
        try {
          final response = await completer.future;
          handler.resolve(response);
        } catch (e) {
          handler.next(err);
        }
        return;
      }

      // 开始刷新流程
      _isRefreshing = true;

      try {
        final refreshToken = await _storage.read(StorageKeys.refreshToken);
        if (refreshToken == null || refreshToken.isEmpty) {
          await _clearTokensSafe();
          _rejectQueue(err);
          handler.next(err);
          return;
        }

        // 使用新的 Dio 实例避免拦截器循环
        final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
        final response = await refreshDio.post(
          ApiConstants.authRefresh,
          data: {'refreshToken': refreshToken},
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          final newAccessToken =
              data['data']?['accessToken'] ?? data['accessToken'];
          final newRefreshToken =
              data['data']?['refreshToken'] ?? data['refreshToken'];

          if (newAccessToken != null) {
            await _storage.write(StorageKeys.accessToken, newAccessToken);
            if (newRefreshToken != null) {
              await _storage.write(StorageKeys.refreshToken, newRefreshToken);
            }

            // 重放原始请求
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            handler.resolve(retryResponse);

            // 处理等待队列
            _processQueue(newAccessToken);
            return;
          }
        }

        // 刷新失败
        await _clearTokensSafe();
        _rejectQueue(err);
        handler.next(err);
      } catch (e) {
        await _clearTokensSafe();
        _rejectQueue(err);
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } catch (e) {
      // 顶层兜底：确保 handler 永远被调用
      handler.next(err);
    }
  }

  void _processQueue(String newToken) {
    for (final queued in _queue) {
      queued.options.headers['Authorization'] = 'Bearer $newToken';
      _dio
          .fetch(queued.options)
          .then(
            (response) => queued.completer.complete(response),
            onError: (e) => queued.completer.completeError(e),
          );
    }
    _queue.clear();
  }

  void _rejectQueue(DioException err) {
    for (final queued in _queue) {
      queued.completer.completeError(err);
    }
    _queue.clear();
  }

  /// 安全的清除 token - 不抛出异常
  Future<void> _clearTokensSafe() async {
    try {
      await _storage.delete(StorageKeys.accessToken);
      await _storage.delete(StorageKeys.refreshToken);
      await _storage.delete(StorageKeys.userInfo);
      onLogout?.call();
    } catch (_) {
      // 清除失败不影响流程
    }
  }
}

class _QueuedRequest {
  final RequestOptions options;
  final Completer<Response> completer;

  _QueuedRequest(this.options, this.completer);
}

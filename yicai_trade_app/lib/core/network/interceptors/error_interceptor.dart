import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../api_exception.dart';

/// 错误拦截器 - 统一错误解析
class ErrorInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 解析后端 Result 格式
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final code = data['code'];
      final codeInt = code is int ? code : int.tryParse('$code') ?? 200;

      if (codeInt != 200) {
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: ApiException(
              code: codeInt,
              message: data['message'] ?? 'error.request_failed'.tr(),
              data: data['data'],
            ),
          ),
        );
        return;
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 如果已经是 ApiException，直接传递
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    // 转换网络错误为友好异常
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const TimeoutException(),
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.connectionError:
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            error: const NetworkException(),
            type: err.type,
          ),
        );
        return;

      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        String message;
        switch (statusCode) {
          case 400:
            message = 'error.bad_request'.tr();
            break;
          case 403:
            message = 'error.forbidden'.tr();
            break;
          case 404:
            message = 'error.not_found'.tr();
            break;
          case 500:
            message = 'error.server_error'.tr();
            break;
          case 502:
            message = 'error.gateway_error'.tr();
            break;
          case 503:
            message = 'error.service_unavailable'.tr();
            break;
          default:
            message = '${'error.request_failed'.tr()} ($statusCode)';
        }
        handler.next(
          DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            error: ApiException(code: statusCode, message: message),
            type: err.type,
          ),
        );
        return;

      default:
        handler.next(err);
    }
  }
}

import 'package:easy_localization/easy_localization.dart';

/// API 业务异常
class ApiException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const ApiException({required this.code, required this.message, this.data});

  @override
  String toString() => 'ApiException(code: $code, message: $message)';

  /// 是否为认证过期
  bool get isUnauthorized => code == 401;

  /// 是否为权限不足
  bool get isForbidden => code == 403;

  /// 是否为资源不存在
  bool get isNotFound => code == 404;

  /// 是否为服务器错误
  bool get isServerError => code >= 500;
}

/// 网络连接异常
class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network connection failed']);

  /// 国际化消息
  String get localizedMessage => 'error.network_error'.tr();

  @override
  String toString() => 'NetworkException: $message';
}

/// 请求超时异常
class TimeoutException implements Exception {
  final String message;
  const TimeoutException([this.message = 'Request timed out']);

  /// 国际化消息
  String get localizedMessage => 'error.timeout'.tr();

  @override
  String toString() => 'TimeoutException: $message';
}

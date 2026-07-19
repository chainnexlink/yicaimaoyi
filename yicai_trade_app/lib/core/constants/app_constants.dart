import 'package:easy_localization/easy_localization.dart';

/// 应用全局常量
class AppConstants {
  AppConstants._();

  static String get appName => 'app.title'.tr();
  static const String appNameEn = 'YiCai Trade';
  static const String appVersion = '1.0.0';

  /// 分页默认参数
  static const int defaultPageSize = 20;
  static const int defaultPage = 0;

  /// 网络超时配置（毫秒）
  static const int connectTimeout = 15000; // 15 秒
  static const int receiveTimeout = 30000; // 30 秒
  static const int sendTimeout = 30000; // 30 秒

  /// 缓存有效期（秒）
  static const int cacheMaxAge = 300; // 5 分钟

  /// Token 提前刷新窗口（毫秒）
  static const int tokenRefreshWindow = 60000; // 1 分钟

  /// WebSocket 重连配置
  static const int wsReconnectInitDelay = 1000;
  static const int wsReconnectMaxDelay = 30000;
  static const double wsReconnectMultiplier = 2.0;

  /// 动画时长
  static const int animDurationFast = 200;
  static const int animDurationNormal = 300;
  static const int animDurationSlow = 500;
}

/// SecureStorage 和 SharedPreferences 键名常量
class StorageKeys {
  StorageKeys._();

  // ============ SecureStorage Keys（敏感数据）============
  static const String accessToken = 'yicai_access_token';
  static const String refreshToken = 'yicai_refresh_token';
  static const String tokenExpiresAt = 'yicai_token_expires_at';
  static const String userInfo = 'yicai_user_info';

  // ============ SharedPreferences Keys（非敏感数据）============
  static const String language = 'platform_language';
  static const String isFirstLaunch = 'yicai_is_first_launch';
  static const String lastUserId = 'yicai_last_user_id';
  static const String themeMode = 'yicai_theme_mode';
  static const String notificationEnabled = 'yicai_notification_enabled';
}

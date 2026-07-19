import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/token_response.dart';
import 'models/user_info.dart';

/// Auth 仓库 - 处理认证相关的 API 调用和 Token 管理
class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository(this._dio, this._storage);

  /// 密码登录 - request 需要有 toJson() 方法
  Future<TokenResponse> login(dynamic request) async {
    final response = await _dio.post(
      ApiConstants.authLogin,
      data: request.toJson(),
    );
    final data = response.data;
    final tokenData = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    final tokenResponse = TokenResponse.fromJson(
      tokenData as Map<String, dynamic>,
    );
    await _saveTokens(tokenResponse);
    return tokenResponse;
  }

  /// 用户注册 - request 需要有 toJson() 方法
  Future<TokenResponse> register(dynamic request) async {
    final response = await _dio.post(
      ApiConstants.authRegister,
      data: request.toJson(),
    );
    final data = response.data;
    final tokenData = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    final tokenResponse = TokenResponse.fromJson(
      tokenData as Map<String, dynamic>,
    );
    await _saveTokens(tokenResponse);
    return tokenResponse;
  }

  /// 获取当前用户信息
  Future<UserInfo> getProfile() async {
    final response = await _dio.get(ApiConstants.authMe);
    final data = response.data;
    final userData = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    final userInfo = UserInfo.fromJson(userData as Map<String, dynamic>);
    await _storage.write(StorageKeys.userInfo, userInfo.toJsonString());
    return userInfo;
  }

  /// 登出
  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.authLogout);
    } catch (_) {
      // 即使 API 失败也清除本地 Token
    }
    await clearTokens();
  }

  /// 检查是否已登录（本地 Token 存在）
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  /// 获取缓存的用户信息
  Future<UserInfo?> getCachedUser() async {
    final jsonStr = await _storage.read(StorageKeys.userInfo);
    return UserInfo.fromJsonString(jsonStr);
  }

  /// 清除所有认证数据
  Future<void> clearTokens() async {
    await _storage.delete(StorageKeys.accessToken);
    await _storage.delete(StorageKeys.refreshToken);
    await _storage.delete(StorageKeys.tokenExpiresAt);
    await _storage.delete(StorageKeys.userInfo);
  }

  /// 保存 Token 到安全存储
  Future<void> _saveTokens(TokenResponse tokenResponse) async {
    await _storage.write(StorageKeys.accessToken, tokenResponse.accessToken);
    await _storage.write(StorageKeys.refreshToken, tokenResponse.refreshToken);

    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + tokenResponse.expiresIn;
    await _storage.write(StorageKeys.tokenExpiresAt, expiresAt.toString());

    if (tokenResponse.user != null) {
      await _storage.write(
        StorageKeys.userInfo,
        tokenResponse.user!.toJsonString(),
      );
    }
  }
}

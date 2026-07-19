import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_info.dart';

/// 认证状态
sealed class AuthState {
  const AuthState();
}

class AuthAuthenticated extends AuthState {
  final UserInfo user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

/// SecureStorage Provider
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService(const FlutterSecureStorage());
});

/// Dio Provider - 不引用 authProvider 避免循环依赖
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  return DioClient.create(secureStorage: storage);
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider), ref.read(secureStorageProvider));
});

/// 全局认证状态 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// 认证状态管理器
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthLoading());

  /// 初始化 - 检查本地 Token 是否有效
  Future<void> initialize() async {
    // 如果已经是认证状态，跳过重复初始化。
    if (state is AuthAuthenticated) return;

    try {
      final isLoggedIn = await _repository.isLoggedIn();
      if (!isLoggedIn) {
        state = const AuthUnauthenticated();
        return;
      }

      try {
        final user = await _repository.getProfile();
        state = AuthAuthenticated(user);
      } catch (_) {
        final cached = await _repository.getCachedUser();
        if (cached != null) {
          state = AuthAuthenticated(cached);
        } else {
          state = const AuthUnauthenticated();
        }
      }
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  /// 密码登录
  Future<void> login(
    String account,
    String password, {
    String? userType,
  }) async {
    state = const AuthLoading();

    try {
      final request = _LoginRequest(
        account: account,
        password: password,
        userType: userType,
      );
      final tokenResponse = await _repository.login(request);

      UserInfo user;
      if (tokenResponse.user != null) {
        user = tokenResponse.user!;
      } else {
        user = await _repository.getProfile();
      }

      state = AuthAuthenticated(user);
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// 注册 - 返回是否为新用户（用于触发引导页）
  Future<bool> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String userType = 'BUYER',
  }) async {
    state = const AuthLoading();
    try {
      final request = _RegisterRequest(
        username: username,
        password: password,
        email: email,
        phone: phone,
        userType: userType,
      );
      final tokenResponse = await _repository.register(request);

      UserInfo user;
      if (tokenResponse.user != null) {
        user = tokenResponse.user!;
      } else {
        user = await _repository.getProfile();
      }

      state = AuthAuthenticated(user);
      return tokenResponse.isNewUser;
    } catch (e) {
      state = const AuthUnauthenticated();
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// 强制登出（Token 刷新失败时调用）
  void forceLogout() {
    _repository.clearTokens();
    state = const AuthUnauthenticated();
  }
}

/// 内联请求模型
class _LoginRequest {
  final String account;
  final String password;
  final String? userType;
  const _LoginRequest({
    required this.account,
    required this.password,
    this.userType,
  });
  Map<String, dynamic> toJson() => {
    'account': account,
    'password': password,
    if (userType != null) 'userType': userType,
  };
}

class _RegisterRequest {
  final String username;
  final String password;
  final String? email;
  final String? phone;
  final String userType;
  const _RegisterRequest({
    required this.username,
    required this.password,
    this.email,
    this.phone,
    this.userType = 'BUYER',
  });
  Map<String, dynamic> toJson() => {
    'username': username,
    'password': password,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    'userType': userType,
  };
}

/// 当前用户信息 Provider（便捷访问）
final currentUserProvider = Provider<UserInfo?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is AuthAuthenticated) {
    return authState.user;
  }
  return null;
});

/// 当前用户ID Provider
final currentUserIdProvider = Provider<int>((ref) {
  return ref.watch(currentUserProvider)?.id ?? 0;
});

/// 当前用户类型 Provider
final currentUserTypeProvider = Provider<String>((ref) {
  return ref.watch(currentUserProvider)?.userType ?? 'BUYER';
});


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';

// ============ Repository ============

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.read(dioProvider));
});

// ============ Dashboard State ============

class AdminDashboardState {
  final AdminDashboardData data;
  final bool isLoading;
  final String? error;

  const AdminDashboardState({
    this.data = const AdminDashboardData(),
    this.isLoading = false,
    this.error,
  });

  AdminDashboardState copyWith({
    AdminDashboardData? data,
    bool? isLoading,
    String? error,
  }) {
    return AdminDashboardState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
      return AdminDashboardNotifier(ref.read(adminRepositoryProvider));
    });

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminRepository _repository;
  AdminDashboardNotifier(this._repository) : super(const AdminDashboardState());

  Future<void> loadData({String period = 'month'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getDashboardStats(period: period);
      state = state.copyWith(data: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadData();
}

// ============ 用户管理 State ============

class AdminUsersState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? error;
  final String? roleFilter;
  final int currentPage;
  final bool hasMore;

  const AdminUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.roleFilter,
    this.currentPage = 0,
    this.hasMore = true,
  });

  AdminUsersState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? error,
    String? roleFilter,
    int? currentPage,
    bool? hasMore,
  }) {
    return AdminUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      roleFilter: roleFilter ?? this.roleFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final adminUsersProvider =
    StateNotifierProvider<AdminUsersNotifier, AdminUsersState>((ref) {
      return AdminUsersNotifier(ref.read(adminRepositoryProvider));
    });

class AdminUsersNotifier extends StateNotifier<AdminUsersState> {
  final AdminRepository _repository;
  AdminUsersNotifier(this._repository) : super(const AdminUsersState());

  Future<void> loadUsers({String? role, String? keyword}) async {
    state = state.copyWith(isLoading: true, error: null, roleFilter: role);
    try {
      final result = await _repository.getUsers(
        role: role,
        keyword: keyword,
        page: 0,
      );
      state = state.copyWith(
        users: result.content,
        isLoading: false,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleUserStatus(int userId, String currentStatus) async {
    try {
      final newStatus = currentStatus == 'ACTIVE' ? 'DISABLED' : 'ACTIVE';
      await _repository.updateUserStatus(userId, newStatus);
      state = state.copyWith(
        users: state.users.map((u) {
          if (u.id == userId) {
            return AdminUser(
              id: u.id,
              username: u.username,
              nickname: u.nickname,
              email: u.email,
              phone: u.phone,
              role: u.role,
              status: newStatus,
              createdAt: u.createdAt,
            );
          }
          return u;
        }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refresh() => loadUsers(role: state.roleFilter);
}

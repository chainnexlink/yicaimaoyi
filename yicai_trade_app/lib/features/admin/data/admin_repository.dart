import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

/// 后台管理仓库 - 对接后端 Admin API
class AdminRepository {
  final Dio _dio;
  AdminRepository(this._dio);

  // ============ 看板统计 ============

  /// GET /api/admin/dashboard/stats
  Future<AdminDashboardData> getDashboardStats({
    String period = 'month',
  }) async {
    final response = await _dio.get(
      ApiConstants.dashboardStats,
      queryParameters: {'period': period},
    );
    final body = _unwrap(response.data);
    return AdminDashboardData.fromJson(body as Map<String, dynamic>);
  }

  // ============ 用户管理 ============

  /// GET /api/admin/users (假设端点)
  Future<PageResult<AdminUser>> getUsers({
    String? keyword,
    String? role,
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (role != null && role.isNotEmpty) params['role'] = role;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _dio.get(
      '${ApiConstants.apiPrefix}/admin/users',
      queryParameters: params,
    );
    return _parsePageResult(response.data, AdminUser.fromJson);
  }

  /// PUT /api/admin/users/{id}/status
  Future<void> updateUserStatus(int userId, String status) async {
    await _dio.put(
      '${ApiConstants.apiPrefix}/admin/users/$userId/status',
      data: {'status': status},
    );
  }

  // ============ 订单管理 ============

  /// GET /api/orders (全部订单)
  Future<PageResult<Map<String, dynamic>>> getOrders({
    String? status,
    String? keyword,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(
      ApiConstants.orders,
      queryParameters: params,
    );
    return _parsePageResult(response.data, (json) => json);
  }

  // ============ 系统监控 ============

  /// GET /api/admin/monitors/summary
  Future<Map<String, dynamic>> getMonitorSummary() async {
    try {
      final response = await _dio.get(
        '${ApiConstants.apiPrefix}/admin/monitors/summary',
      );
      return _unwrap(response.data) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  // ============ 工具 ============

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<T> _parsePageResult<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = _unwrap(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, fromJson);
    }
    if (body is List) {
      return PageResult(
        content: body.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
        totalElements: body.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: body.length,
      );
    }
    return PageResult(
      content: <T>[],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 20,
    );
  }
}

// ============ 数据模型 ============

class AdminDashboardData {
  final int totalUsers;
  final int totalBuyers;
  final int totalSuppliers;
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalRevenue;
  final double monthRevenue;
  final int activeMonitors;
  final int pendingAlerts;
  final List<AdminOrderTrend> orderTrend;
  final List<AdminRecentOrder> recentOrders;

  const AdminDashboardData({
    this.totalUsers = 0,
    this.totalBuyers = 0,
    this.totalSuppliers = 0,
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.completedOrders = 0,
    this.totalRevenue = 0,
    this.monthRevenue = 0,
    this.activeMonitors = 0,
    this.pendingAlerts = 0,
    this.orderTrend = const [],
    this.recentOrders = const [],
  });

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      totalUsers: json['totalUsers'] ?? 0,
      totalBuyers: json['totalBuyers'] ?? json['buyerCount'] ?? 0,
      totalSuppliers: json['totalSuppliers'] ?? json['supplierCount'] ?? 0,
      totalOrders: json['totalOrders'] ?? json['orderCount'] ?? 0,
      pendingOrders: json['pendingOrders'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      monthRevenue: (json['monthRevenue'] ?? json['revenue'] ?? 0).toDouble(),
      activeMonitors: json['activeMonitors'] ?? 0,
      pendingAlerts: json['pendingAlerts'] ?? 0,
      orderTrend:
          (json['orderTrend'] as List<dynamic>?)
              ?.map((e) => AdminOrderTrend.fromJson(e))
              .toList() ??
          [],
      recentOrders:
          (json['recentOrders'] as List<dynamic>?)
              ?.map((e) => AdminRecentOrder.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class AdminOrderTrend {
  final String label;
  final int count;
  const AdminOrderTrend({required this.label, required this.count});
  factory AdminOrderTrend.fromJson(Map<String, dynamic> json) {
    return AdminOrderTrend(
      label: json['label'] ?? json['month'] ?? '',
      count: json['count'] ?? json['value'] ?? 0,
    );
  }
}

class AdminRecentOrder {
  final int id;
  final String orderNo;
  final String buyerName;
  final String supplierName;
  final double amount;
  final String status;
  final String? createdAt;

  const AdminRecentOrder({
    required this.id,
    required this.orderNo,
    this.buyerName = '',
    this.supplierName = '',
    this.amount = 0,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory AdminRecentOrder.fromJson(Map<String, dynamic> json) {
    return AdminRecentOrder(
      id: json['id'] ?? 0,
      orderNo: json['orderNo'] ?? '',
      buyerName: json['buyerName'] ?? '',
      supplierName: json['supplierName'] ?? '',
      amount: (json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get statusLabel {
    final labels = {
      'PENDING': 'admin.order_status_pending'.tr(),
      'CONFIRMED': 'admin.order_status_confirmed'.tr(),
      'PAID': 'admin.order_status_paid'.tr(),
      'IN_PRODUCTION': 'admin.order_status_in_production'.tr(),
      'SHIPPED': 'admin.order_status_shipped'.tr(),
      'COMPLETED': 'admin.order_status_completed'.tr(),
      'CANCELLED': 'admin.order_status_cancelled'.tr(),
    };
    return labels[status] ?? status;
  }
}

class AdminUser {
  final int id;
  final String username;
  final String? nickname;
  final String? email;
  final String? phone;
  final String role;
  final String status;
  final String? createdAt;

  const AdminUser({
    required this.id,
    required this.username,
    this.nickname,
    this.email,
    this.phone,
    this.role = 'BUYER',
    this.status = 'ACTIVE',
    this.createdAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      nickname: json['nickname'],
      email: json['email'],
      phone: json['phone'],
      role: json['role'] ?? 'BUYER',
      status: json['status'] ?? 'ACTIVE',
      createdAt: json['createdAt']?.toString(),
    );
  }

  String get roleLabel {
    final labels = {
      'ADMIN': 'admin.role_admin'.tr(),
      'BUYER': 'admin.role_buyer'.tr(),
      'SUPPLIER': 'admin.role_supplier'.tr(),
    };
    return labels[role] ?? role;
  }
}

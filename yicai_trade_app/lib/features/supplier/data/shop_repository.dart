import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class ShopInfo {
  final int id;
  final int supplierId;
  final String shopName;
  final String? logo;
  final String? banner;
  final String? description;
  final String? industry;
  final String status;
  final int visitCount;
  final DateTime? createdAt;

  const ShopInfo({
    required this.id,
    required this.supplierId,
    required this.shopName,
    this.logo,
    this.banner,
    this.description,
    this.industry,
    this.status = 'ACTIVE',
    this.visitCount = 0,
    this.createdAt,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) => ShopInfo(
        id: json['id'] ?? 0,
        supplierId: json['supplierId'] ?? 0,
        shopName: json['shopName'] ?? json['name'] ?? '',
        logo: json['logo'],
        banner: json['banner'],
        description: json['description'],
        industry: json['industry'],
        status: json['status'] ?? 'ACTIVE',
        visitCount: json['visitCount'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}

class ShopDashboard {
  final int totalVisits;
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;

  const ShopDashboard({
    this.totalVisits = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.totalProducts = 0,
  });

  factory ShopDashboard.fromJson(Map<String, dynamic> json) => ShopDashboard(
        totalVisits: json['totalVisits'] ?? 0,
        totalOrders: json['totalOrders'] ?? 0,
        totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
        totalProducts: json['totalProducts'] ?? 0,
      );
}

/// 店铺仓库 - 匹配后端 ShopController
class ShopRepository {
  final Dio _dio;
  ShopRepository(this._dio);

  /// 创建店铺: POST /api/shop
  Future<ShopInfo> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.shop, data: data);
    return ShopInfo.fromJson(_unwrap(r.data));
  }

  /// 按供应商获取店铺: GET /api/shop/supplier/{supplierId}
  Future<ShopInfo?> getBySupplierId(int supplierId) async {
    try {
      final r = await _dio.get(ApiConstants.shopBySupplier(supplierId));
      return ShopInfo.fromJson(_unwrap(r.data));
    } catch (_) {}
    return null;
  }

  /// 获取店铺详情: GET /api/shop/{id}
  Future<ShopInfo> getById(int id) async {
    final r = await _dio.get(ApiConstants.shopDetail(id));
    return ShopInfo.fromJson(_unwrap(r.data));
  }

  /// 更新店铺信息: PUT /api/shop/supplier/{supplierId}/info
  Future<ShopInfo> updateInfo(
      int supplierId, Map<String, dynamic> data) async {
    final r = await _dio.put(ApiConstants.shopUpdateInfo(supplierId), data: data);
    return ShopInfo.fromJson(_unwrap(r.data));
  }

  /// 更新店铺装修: PUT /api/shop/supplier/{supplierId}/decoration
  Future<ShopInfo> updateDecoration(
      int supplierId, Map<String, dynamic> data) async {
    final r = await _dio.put(
        ApiConstants.shopUpdateDecoration(supplierId),
        data: data);
    return ShopInfo.fromJson(_unwrap(r.data));
  }

  /// 记录店铺访问: POST /api/shop/{id}/visit
  Future<void> visit(int id) async {
    await _dio.post('${ApiConstants.shop}/$id/visit');
  }

  /// 店铺列表（搜索/筛选）: GET /api/shop
  Future<PageResult<ShopInfo>> list({
    String? status,
    String? industry,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    if (industry != null) params['industry'] = industry;
    if (keyword != null) params['keyword'] = keyword;
    final r = await _dio.get(ApiConstants.shop, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 店铺数据看板: GET /api/shop/supplier/{supplierId}/dashboard
  Future<ShopDashboard> getDashboard(int supplierId,
      {required String startDate, required String endDate}) async {
    final r = await _dio.get(ApiConstants.shopDashboard(supplierId),
        queryParameters: {'startDate': startDate, 'endDate': endDate});
    return ShopDashboard.fromJson(_unwrap(r.data));
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic> ? data['data'] : data;
    }
    return {};
  }

  PageResult<ShopInfo> _parsePage(dynamic data) {
    final body =
        data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => ShopInfo.fromJson(j));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => ShopInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: body.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: body.length,
      );
    }
    return const PageResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 10,
    );
  }
}

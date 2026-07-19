import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/supplier_product_model.dart';

/// 供应商中心仓库 - 对接后端供应商管理API
class SupplierCenterRepository {
  final Dio _dio;
  SupplierCenterRepository(this._dio);

  // ============ 产品管理 ============

  /// 获取供应商产品列表: GET /api/supplier/products
  Future<PageResult<SupplierProductModel>> getProducts({
    String? keyword,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.supplierProducts,
      queryParameters: params,
    );
    return _parsePageResult<SupplierProductModel>(
      response.data,
      (json) => SupplierProductModel.fromJson(json),
    );
  }

  /// 添加产品: POST /api/supplier/products
  Future<SupplierProductModel> createProduct(
    Map<String, dynamic> productData,
  ) async {
    final response = await _dio.post(
      ApiConstants.supplierProducts,
      data: productData,
    );
    final data = _extractData(response.data);
    return SupplierProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// 编辑产品: PUT /api/supplier/products/{id}
  Future<SupplierProductModel> updateProduct(
    int id,
    Map<String, dynamic> productData,
  ) async {
    final response = await _dio.put(
      '${ApiConstants.supplierProducts}/$id',
      data: productData,
    );
    final data = _extractData(response.data);
    return SupplierProductModel.fromJson(data as Map<String, dynamic>);
  }

  /// 删除产品: DELETE /api/supplier/products/{id}
  Future<void> deleteProduct(int id) async {
    await _dio.delete('${ApiConstants.supplierProducts}/$id');
  }

  /// 更新产品状态: PUT /api/supplier/products/{id}/status
  Future<void> updateProductStatus(int id, String status) async {
    await _dio.put(
      '${ApiConstants.supplierProducts}/$id/status',
      data: {'status': status},
    );
  }

  // ============ 供应商订单管理 ============

  /// 获取供应商订单列表: GET /api/orders/supplier/{supplierId}
  Future<PageResult<Map<String, dynamic>>> getOrders(
    int supplierId, {
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.isNotEmpty) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.ordersBySupplier(supplierId),
      queryParameters: params,
    );
    return _parsePageResult<Map<String, dynamic>>(
      response.data,
      (json) => json,
    );
  }

  // ============ 供应商入驻 ============

  /// 提交入驻申请: POST /api/supplier/apply
  Future<Map<String, dynamic>> submitApplication(
    Map<String, dynamic> applicationData,
  ) async {
    final response = await _dio.post(
      ApiConstants.supplierApply,
      data: applicationData,
    );
    return _extractData(response.data) as Map<String, dynamic>;
  }

  /// 查看申请状态: GET /api/supplier/apply
  Future<Map<String, dynamic>> getApplicationStatus() async {
    final response = await _dio.get(ApiConstants.supplierApply);
    return _extractData(response.data) as Map<String, dynamic>;
  }

  // ============ 供应商概览 ============

  /// 获取概览统计数据: GET /api/supplier/profile (含统计字段)
  Future<SupplierDashboardStats> getDashboardStats() async {
    final response = await _dio.get(ApiConstants.supplierProfile);
    final data = _extractData(response.data);
    if (data is Map<String, dynamic>) {
      return SupplierDashboardStats.fromJson(data);
    }
    return const SupplierDashboardStats();
  }

  // ============ 工具方法 ============

  dynamic _extractData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<T> _parsePageResult<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final body = _extractData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, fromJsonT);
    }
    if (body is List) {
      return PageResult(
        content: body.map((e) => fromJsonT(e as Map<String, dynamic>)).toList(),
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
      pageSize: 10,
    );
  }
}

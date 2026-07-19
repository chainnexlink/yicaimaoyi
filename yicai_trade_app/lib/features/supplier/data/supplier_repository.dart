import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/supplier_model.dart';

/// 供应商仓库 - 匹配后端 AdminSupplierController 端点
class SupplierRepository {
  final Dio _dio;
  SupplierRepository(this._dio);

  /// 供应商列表: GET /api/admin/suppliers
  Future<PageResult<SupplierModel>> getSuppliers({
    String? keyword,
    String? category,
    String? sortBy,
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (sortBy != null && sortBy.isNotEmpty) params['sort'] = sortBy;
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.adminSuppliers,
      queryParameters: params,
    );
    return _parsePageResult(response.data);
  }

  /// 供应商详情: GET /api/admin/suppliers (暂用列表端点过滤)
  /// 或通过 GET /api/supplier/profile 获取当前供应商自身资料
  Future<SupplierModel> getSupplierDetail(int id) async {
    final response = await _dio.get(
      '${ApiConstants.adminSuppliers}/$id',
    );
    final data = response.data;
    final body = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return SupplierModel.fromJson(body as Map<String, dynamic>);
  }

  /// 获取自身供应商资料: GET /api/supplier/profile
  Future<SupplierModel> getMyProfile() async {
    final response = await _dio.get(ApiConstants.supplierProfile);
    final data = response.data;
    final body = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    return SupplierModel.fromJson(body as Map<String, dynamic>);
  }

  PageResult<SupplierModel> _parsePageResult(dynamic data) {
    final body =
        data is Map<String, dynamic> && data.containsKey('data')
            ? data['data']
            : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => SupplierModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => SupplierModel.fromJson(e as Map<String, dynamic>))
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

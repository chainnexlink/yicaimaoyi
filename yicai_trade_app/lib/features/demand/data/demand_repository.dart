import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class DemandModel {
  final int id;
  final String? demandNo;
  final String title;
  final String? description;
  final String? category;
  final String status;
  final int? buyerId;
  final int viewCount;
  final int responseCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DemandModel({
    required this.id,
    this.demandNo,
    required this.title,
    this.description,
    this.category,
    this.status = 'PENDING',
    this.buyerId,
    this.viewCount = 0,
    this.responseCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory DemandModel.fromJson(Map<String, dynamic> json) => DemandModel(
        id: json['id'] ?? 0,
        demandNo: json['demandNo'],
        title: json['title'] ?? '',
        description: json['description'],
        category: json['category'],
        status: json['status'] ?? 'PENDING',
        buyerId: json['buyerId'],
        viewCount: json['viewCount'] ?? 0,
        responseCount: json['responseCount'] ?? 0,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
      );
}

/// 需求仓库 - 匹配后端 DemandController
class DemandRepository {
  final Dio _dio;
  DemandRepository(this._dio);

  /// 创建需求: POST /api/admin/demands
  Future<DemandModel> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.demands, data: data);
    return DemandModel.fromJson(_unwrap(r.data));
  }

  /// 更新需求: PUT /api/admin/demands/{id}
  Future<DemandModel> update(int id, Map<String, dynamic> data) async {
    final r = await _dio.put(ApiConstants.demandDetail(id), data: data);
    return DemandModel.fromJson(_unwrap(r.data));
  }

  /// 删除需求: DELETE /api/admin/demands/{id}
  Future<void> delete(int id) async {
    await _dio.delete(ApiConstants.demandDetail(id));
  }

  /// 获取需求详情: GET /api/admin/demands/{id}
  Future<DemandModel> getById(int id) async {
    final r = await _dio.get(ApiConstants.demandDetail(id));
    return DemandModel.fromJson(_unwrap(r.data));
  }

  /// 分页查询需求列表: GET /api/admin/demands
  Future<PageResult<DemandModel>> list({
    String? status,
    String? category,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    if (category != null) params['category'] = category;
    final r = await _dio.get(ApiConstants.demands, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 查询采购商的需求: GET /api/admin/demands/buyer/{buyerId}
  Future<PageResult<DemandModel>> listByBuyer(int buyerId,
      {int page = 0, int size = 10}) async {
    final r = await _dio.get(ApiConstants.demandsByBuyer(buyerId),
        queryParameters: {'page': page, 'size': size});
    return _parsePage(r.data);
  }

  /// 关闭需求: POST /api/admin/demands/{id}/close
  Future<void> close(int id) async {
    await _dio.post('${ApiConstants.demandDetail(id)}/close');
  }

  /// 增加浏览量: POST /api/admin/demands/{id}/view
  Future<void> incrementView(int id) async {
    await _dio.post('${ApiConstants.demandDetail(id)}/view');
  }

  /// 增加响应数: POST /api/admin/demands/{id}/response
  Future<void> incrementResponse(int id) async {
    await _dio.post('${ApiConstants.demandDetail(id)}/response');
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['data'] is Map<String, dynamic> ? data['data'] : data;
    }
    return {};
  }

  PageResult<DemandModel> _parsePage(dynamic data) {
    final body =
        data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => DemandModel.fromJson(j));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => DemandModel.fromJson(e as Map<String, dynamic>))
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

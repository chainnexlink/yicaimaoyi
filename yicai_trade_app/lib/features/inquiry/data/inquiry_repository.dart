import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/inquiry_model.dart';

/// 询盘仓库 - 匹配后端 InquiryController 端点
class InquiryRepository {
  final Dio _dio;
  InquiryRepository(this._dio);

  /// 采购商询价列表: GET /api/inquiries/buyer/{buyerId}
  Future<PageResult<InquiryModel>> getInquiriesByBuyer(
    int buyerId, {
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.inquiriesByBuyer(buyerId),
      queryParameters: params,
    );
    return _parsePageResult(response.data);
  }

  /// 公开询价列表: GET /api/inquiries/open
  Future<PageResult<InquiryModel>> getOpenInquiries({
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.inquiriesOpen,
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePageResult(response.data);
  }

  /// 询价详情: GET /api/inquiries/{id}
  Future<InquiryModel> getInquiryDetail(int id) async {
    final response = await _dio.get('${ApiConstants.inquiries}/$id');
    final body = _unwrapData(response.data);
    return InquiryModel.fromJson(body as Map<String, dynamic>);
  }

  /// 创建询价: POST /api/inquiries?buyerId={buyerId}
  Future<InquiryModel> createInquiry(
    int buyerId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post(
      ApiConstants.inquiries,
      data: data,
      queryParameters: {'buyerId': buyerId},
    );
    final body = _unwrapData(response.data);
    return InquiryModel.fromJson(body as Map<String, dynamic>);
  }

  /// 关闭询价: POST /api/inquiries/{id}/close
  Future<void> closeInquiry(int id) async {
    await _dio.post('${ApiConstants.inquiries}/$id/close');
  }

  /// 提交报价: POST /api/inquiries/quotations?supplierId={supplierId}
  Future<void> submitQuotation(
    int supplierId,
    Map<String, dynamic> quotationData,
  ) async {
    await _dio.post(
      '${ApiConstants.inquiries}/quotations',
      data: quotationData,
      queryParameters: {'supplierId': supplierId},
    );
  }

  /// 接受报价: POST /api/inquiries/quotations/{quotationId}/accept?buyerId={buyerId}
  Future<void> acceptQuotation(int quotationId, int buyerId) async {
    await _dio.post(
      '${ApiConstants.inquiries}/quotations/$quotationId/accept',
      queryParameters: {'buyerId': buyerId},
    );
  }

  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<InquiryModel> _parsePageResult(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => InquiryModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => InquiryModel.fromJson(e as Map<String, dynamic>))
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

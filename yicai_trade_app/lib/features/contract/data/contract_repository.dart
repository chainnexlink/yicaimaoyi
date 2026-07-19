import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/contract_model.dart';

/// 合同仓库 - 匹配后端 ContractController 端点
class ContractRepository {
  final Dio _dio;
  ContractRepository(this._dio);

  /// 采购商合同列表: GET /api/contracts/buyer/{buyerId}
  Future<PageResult<ContractModel>> getContractsByBuyer(
    int buyerId, {
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.contractsByBuyer(buyerId),
      queryParameters: params,
    );
    return _parsePageResult(response.data);
  }

  /// 供应商合同列表: GET /api/contracts/supplier/{supplierId}
  Future<PageResult<ContractModel>> getContractsBySupplier(
    int supplierId, {
    String? status,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.contractsBySupplier(supplierId),
      queryParameters: params,
    );
    return _parsePageResult(response.data);
  }

  /// 合同详情: GET /api/contracts/{id}
  Future<ContractModel> getContractDetail(int id) async {
    final response = await _dio.get('${ApiConstants.contracts}/$id');
    final body = _unwrapData(response.data);
    return ContractModel.fromJson(body as Map<String, dynamic>);
  }

  /// 创建合同: POST /api/contracts?buyerId={buyerId}
  Future<ContractModel> createContract(
    int buyerId,
    Map<String, dynamic> contractData,
  ) async {
    final response = await _dio.post(
      ApiConstants.contracts,
      data: contractData,
      queryParameters: {'buyerId': buyerId},
    );
    final body = _unwrapData(response.data);
    return ContractModel.fromJson(body as Map<String, dynamic>);
  }

  /// 采购商签署合同: POST /api/contracts/{id}/sign/buyer?buyerId={buyerId}
  Future<void> signContractAsBuyer(
    int contractId,
    int buyerId, {
    Map<String, dynamic>? signData,
  }) async {
    await _dio.post(
      '${ApiConstants.contracts}/$contractId/sign/buyer',
      queryParameters: {'buyerId': buyerId},
      data: signData ?? {},
    );
  }

  /// 供应商签署合同: POST /api/contracts/{id}/sign/supplier?supplierId={supplierId}
  Future<void> signContractAsSupplier(
    int contractId,
    int supplierId, {
    Map<String, dynamic>? signData,
  }) async {
    await _dio.post(
      '${ApiConstants.contracts}/$contractId/sign/supplier',
      queryParameters: {'supplierId': supplierId},
      data: signData ?? {},
    );
  }

  /// 获取合同模板列表: GET /api/contracts/templates
  Future<List<Map<String, dynamic>>> getTemplates({String? category}) async {
    final response = await _dio.get(
      ApiConstants.contractTemplates,
      queryParameters: category != null ? {'category': category} : null,
    );
    final body = _unwrapData(response.data);
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// 获取模板详情: GET /api/contracts/templates/{templateId}
  Future<Map<String, dynamic>> getTemplateDetail(int templateId) async {
    final r = await _dio.get('${ApiConstants.contractTemplates}/$templateId');
    final body = _unwrapData(r.data);
    return body is Map<String, dynamic> ? body : {};
  }

  /// 根据合同号查询: GET /api/contracts/no/{contractNo}
  Future<ContractModel> getByContractNo(String contractNo) async {
    final r = await _dio.get('${ApiConstants.contracts}/no/$contractNo');
    final body = _unwrapData(r.data);
    return ContractModel.fromJson(body as Map<String, dynamic>);
  }

  /// 生成订单: POST /api/contracts/{id}/generate-order
  Future<Map<String, dynamic>> generateOrder(int contractId) async {
    final r = await _dio.post(
      '${ApiConstants.contracts}/$contractId/generate-order',
    );
    final body = _unwrapData(r.data);
    return body is Map<String, dynamic> ? body : {};
  }

  /// 申请变更: POST /api/contracts/{id}/changes
  Future<void> requestChange(
    int contractId,
    Map<String, dynamic> changeData,
  ) async {
    await _dio.post(
      '${ApiConstants.contracts}/$contractId/changes',
      data: changeData,
    );
  }

  /// 审批变更: PUT /api/contracts/changes/{changeLogId}/approve
  Future<void> approveChange(
    int changeLogId, {
    required bool approved,
    String? remark,
  }) async {
    await _dio.put(
      '${ApiConstants.contracts}/changes/$changeLogId/approve',
      data: {'approved': approved, 'remark': ?remark},
    );
  }

  /// 终止合同: PUT /api/contracts/{id}/terminate
  Future<void> terminateContract(int contractId, {String? reason}) async {
    await _dio.put(
      '${ApiConstants.contracts}/$contractId/terminate',
      data: {'reason': ?reason},
    );
  }

  /// 完成合同: PUT /api/contracts/{id}/complete
  Future<void> completeContract(int contractId) async {
    await _dio.put('${ApiConstants.contracts}/$contractId/complete');
  }

  /// 获取买家待处理合同: GET /api/contracts/pending/buyer/{buyerId}
  Future<List<ContractModel>> getPendingByBuyer(int buyerId) async {
    final r = await _dio.get(
      '${ApiConstants.contracts}/pending/buyer/$buyerId',
    );
    return _parseList(r.data);
  }

  /// 获取供应商待处理合同: GET /api/contracts/pending/supplier/{supplierId}
  Future<List<ContractModel>> getPendingBySupplier(int supplierId) async {
    final r = await _dio.get(
      '${ApiConstants.contracts}/pending/supplier/$supplierId',
    );
    return _parseList(r.data);
  }

  /// 指定供应商: PUT /api/contracts/{id}/assign-supplier
  Future<void> assignSupplier(int contractId, int supplierId) async {
    await _dio.put(
      '${ApiConstants.contracts}/$contractId/assign-supplier',
      queryParameters: {'supplierId': supplierId},
    );
  }

  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  List<ContractModel> _parseList(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return (body['content'] as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (body is List) {
      return body
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  PageResult<ContractModel> _parsePageResult(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => ContractModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
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

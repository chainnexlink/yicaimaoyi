import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

/// 纠纷模型
class DisputeOrder {
  final int id;
  final int orderId;
  final String type; // QUALITY, DELIVERY, FRAUD, PRICE, OTHER
  final String
  status; // PENDING, REVIEWING, MEDIATING, RULED, ENFORCING, CLOSED
  final String title;
  final String description;
  final int? buyerId;
  final int? supplierId;
  final String? buyerName;
  final String? supplierName;
  final String? handlerId;
  final String? ruling;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const DisputeOrder({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    this.buyerId,
    this.supplierId,
    this.buyerName,
    this.supplierName,
    this.handlerId,
    this.ruling,
    this.createdAt,
    this.updatedAt,
  });

  factory DisputeOrder.fromJson(Map<String, dynamic> json) => DisputeOrder(
    id: json['id'] ?? 0,
    orderId: json['orderId'] ?? 0,
    type: json['type'] ?? '',
    status: json['status'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    buyerId: json['buyerId'],
    supplierId: json['supplierId'],
    buyerName: json['buyerName'],
    supplierName: json['supplierName'],
    handlerId: json['handlerId']?.toString(),
    ruling: json['ruling'],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString())
        : null,
  );

  String get statusLabel {
    final labels = {
      'PENDING': 'dispute.status_pending'.tr(),
      'REVIEWING': 'dispute.status_reviewing'.tr(),
      'MEDIATING': 'dispute.status_mediating'.tr(),
      'RULED': 'dispute.status_ruled'.tr(),
      'ENFORCING': 'dispute.status_enforcing'.tr(),
      'CLOSED': 'dispute.status_closed'.tr(),
      'WITHDRAWN': 'dispute.status_withdrawn'.tr(),
    };
    return labels[status] ?? status;
  }
}

/// 纠纷仓库 - 匹配后端 DisputeController (/api/dispute)
class DisputeRepository {
  final Dio _dio;
  DisputeRepository(this._dio);

  /// 创建纠纷: POST /api/dispute
  Future<DisputeOrder> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.dispute, data: data);
    final body = _unwrap(r.data);
    return DisputeOrder.fromJson(body as Map<String, dynamic>);
  }

  /// 获取纠纷详情: GET /api/dispute/{id}
  Future<DisputeOrder> getDetail(int id) async {
    final r = await _dio.get('${ApiConstants.dispute}/$id');
    final body = _unwrap(r.data);
    return DisputeOrder.fromJson(body as Map<String, dynamic>);
  }

  /// 纠纷列表: GET /api/dispute
  Future<PageResult<DisputeOrder>> list({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    final r = await _dio.get(ApiConstants.dispute, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 发送纠纷消息: POST /api/dispute/{id}/message
  Future<void> sendMessage(int id, Map<String, dynamic> messageData) async {
    await _dio.post('${ApiConstants.dispute}/$id/message', data: messageData);
  }

  /// 撤回纠纷: POST /api/dispute/{id}/withdraw
  Future<void> withdraw(int id) async {
    await _dio.post('${ApiConstants.dispute}/$id/withdraw');
  }

  /// 获取纠纷统计: GET /api/dispute/stats
  Future<Map<String, dynamic>> getStats() async {
    final r = await _dio.get('${ApiConstants.dispute}/stats');
    final body = _unwrap(r.data);
    return body is Map<String, dynamic> ? body : {};
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<DisputeOrder> _parsePage(dynamic data) {
    final body = _unwrap(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => DisputeOrder.fromJson(j));
    }
    if (body is List) {
      final list = body
          .map((e) => DisputeOrder.fromJson(e as Map<String, dynamic>))
          .toList();
      return PageResult(
        content: list,
        totalElements: list.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: list.length,
      );
    }
    return const PageResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 20,
    );
  }
}

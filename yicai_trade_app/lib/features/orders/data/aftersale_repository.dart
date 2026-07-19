import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

/// 售后工单模型
class AftersaleOrder {
  final int id;
  final int orderId;
  final String type; // REFUND, EXCHANGE, REPAIR
  final String status; // PENDING, APPROVED, REJECTED, SHIPPING, COMPLETED
  final String reason;
  final double? refundAmount;
  final String? description;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AftersaleOrder({
    required this.id,
    required this.orderId,
    required this.type,
    required this.status,
    required this.reason,
    this.refundAmount,
    this.description,
    this.images = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory AftersaleOrder.fromJson(Map<String, dynamic> json) => AftersaleOrder(
    id: json['id'] ?? 0,
    orderId: json['orderId'] ?? 0,
    type: json['type'] ?? '',
    status: json['status'] ?? '',
    reason: json['reason'] ?? '',
    refundAmount: json['refundAmount'] != null
        ? (json['refundAmount'] as num).toDouble()
        : null,
    description: json['description'],
    images: json['images'] is List
        ? (json['images'] as List).map((e) => e.toString()).toList()
        : const [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString())
        : null,
  );

  String get statusLabel {
    final labels = {
      'PENDING': 'aftersale.status_pending'.tr(),
      'APPROVED': 'aftersale.status_approved'.tr(),
      'REJECTED': 'aftersale.status_rejected'.tr(),
      'SHIPPING': 'aftersale.status_shipping'.tr(),
      'RECEIVED': 'aftersale.status_received'.tr(),
      'REFUNDED': 'aftersale.status_refunded'.tr(),
      'EXCHANGED': 'aftersale.status_exchanged'.tr(),
      'COMPLETED': 'aftersale.status_completed'.tr(),
      'APPEALING': 'aftersale.status_appealing'.tr(),
    };
    return labels[status] ?? status;
  }

  String get typeLabel {
    final labels = {
      'REFUND': 'aftersale.type_refund'.tr(),
      'EXCHANGE': 'aftersale.type_exchange'.tr(),
      'REPAIR': 'aftersale.type_repair'.tr(),
    };
    return labels[type] ?? type;
  }
}

/// 售后仓库 - 匹配后端 AftersaleController (/api/aftersale)
class AftersaleRepository {
  final Dio _dio;
  AftersaleRepository(this._dio);

  /// 创建售后工单: POST /api/aftersale
  Future<AftersaleOrder> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.aftersale, data: data);
    final body = _unwrap(r.data);
    return AftersaleOrder.fromJson(body as Map<String, dynamic>);
  }

  /// 获取售后详情: GET /api/aftersale/{id}
  Future<AftersaleOrder> getDetail(int id) async {
    final r = await _dio.get('${ApiConstants.aftersale}/$id');
    final body = _unwrap(r.data);
    return AftersaleOrder.fromJson(body as Map<String, dynamic>);
  }

  /// 售后列表: GET /api/aftersale
  Future<PageResult<AftersaleOrder>> list({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    final r = await _dio.get(ApiConstants.aftersale, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 寄回退货: POST /api/aftersale/{id}/ship-return
  Future<void> shipReturn(int id, Map<String, dynamic> shipData) async {
    await _dio.post(
      '${ApiConstants.aftersale}/$id/ship-return',
      data: shipData,
    );
  }

  /// 申诉: POST /api/aftersale/{id}/appeal
  Future<void> appeal(int id, Map<String, dynamic> appealData) async {
    await _dio.post('${ApiConstants.aftersale}/$id/appeal', data: appealData);
  }

  /// 获取售后统计: GET /api/aftersale/stats
  Future<Map<String, dynamic>> getStats() async {
    final r = await _dio.get('${ApiConstants.aftersale}/stats');
    final body = _unwrap(r.data);
    return body is Map<String, dynamic> ? body : {};
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<AftersaleOrder> _parsePage(dynamic data) {
    final body = _unwrap(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => AftersaleOrder.fromJson(j));
    }
    if (body is List) {
      final list = body
          .map((e) => AftersaleOrder.fromJson(e as Map<String, dynamic>))
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

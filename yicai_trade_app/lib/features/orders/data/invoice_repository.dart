import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

/// 发票模型
class InvoiceInfo {
  final int id;
  final String invoiceNo;
  final int orderId;
  final String status; // DRAFT, ISSUED, SENT, CONFIRMED, CANCELLED, VOIDED
  final String type; // PROFORMA, COMMERCIAL, VAT
  final double amount;
  final String? currency;
  final String? buyerName;
  final String? supplierName;
  final DateTime? issueDate;
  final DateTime? createdAt;

  const InvoiceInfo({
    required this.id,
    required this.invoiceNo,
    required this.orderId,
    required this.status,
    required this.type,
    required this.amount,
    this.currency,
    this.buyerName,
    this.supplierName,
    this.issueDate,
    this.createdAt,
  });

  factory InvoiceInfo.fromJson(Map<String, dynamic> json) => InvoiceInfo(
    id: json['id'] ?? 0,
    invoiceNo: json['invoiceNo'] ?? '',
    orderId: json['orderId'] ?? 0,
    status: json['status'] ?? '',
    type: json['type'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    currency: json['currency'],
    buyerName: json['buyerName'],
    supplierName: json['supplierName'],
    issueDate: json['issueDate'] != null
        ? DateTime.tryParse(json['issueDate'].toString())
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );

  String get statusLabel {
    final labels = {
      'DRAFT': 'invoice.status_draft'.tr(),
      'ISSUED': 'invoice.status_issued'.tr(),
      'SENT': 'invoice.status_sent'.tr(),
      'CONFIRMED': 'invoice.status_confirmed'.tr(),
      'CANCELLED': 'invoice.status_cancelled'.tr(),
      'VOIDED': 'invoice.status_voided'.tr(),
    };
    return labels[status] ?? status;
  }
}

/// 发票仓库 - 匹配后端 InvoiceController (/api/invoice)
class InvoiceRepository {
  final Dio _dio;
  InvoiceRepository(this._dio);

  /// 创建发票: POST /api/invoice
  Future<InvoiceInfo> create(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.invoice, data: data);
    final body = _unwrap(r.data);
    return InvoiceInfo.fromJson(body as Map<String, dynamic>);
  }

  /// 获取发票详情: GET /api/invoice/{id}
  Future<InvoiceInfo> getDetail(int id) async {
    final r = await _dio.get('${ApiConstants.invoice}/$id');
    final body = _unwrap(r.data);
    return InvoiceInfo.fromJson(body as Map<String, dynamic>);
  }

  /// 根据发票号查询: GET /api/invoice/no/{invoiceNo}
  Future<InvoiceInfo> getByNo(String invoiceNo) async {
    final r = await _dio.get('${ApiConstants.invoice}/no/$invoiceNo');
    final body = _unwrap(r.data);
    return InvoiceInfo.fromJson(body as Map<String, dynamic>);
  }

  /// 发票列表: GET /api/invoice
  Future<PageResult<InvoiceInfo>> list({
    String? status,
    int page = 0,
    int size = 20,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    final r = await _dio.get(ApiConstants.invoice, queryParameters: params);
    return _parsePage(r.data);
  }

  /// 订单发票列表: GET /api/invoice/order/{orderId}
  Future<List<InvoiceInfo>> getByOrder(int orderId) async {
    final r = await _dio.get('${ApiConstants.invoice}/order/$orderId');
    final body = _unwrap(r.data);
    if (body is List) {
      return body
          .map((e) => InvoiceInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 开具发票: POST /api/invoice/{id}/issue
  Future<void> issue(int id) async {
    await _dio.post('${ApiConstants.invoice}/$id/issue');
  }

  /// 发送发票: POST /api/invoice/{id}/send
  Future<void> send(int id) async {
    await _dio.post('${ApiConstants.invoice}/$id/send');
  }

  /// 确认收到: POST /api/invoice/{id}/confirm
  Future<void> confirm(int id) async {
    await _dio.post('${ApiConstants.invoice}/$id/confirm');
  }

  /// 取消发票: POST /api/invoice/{id}/cancel
  Future<void> cancel(int id) async {
    await _dio.post('${ApiConstants.invoice}/$id/cancel');
  }

  /// 获取发票统计: GET /api/invoice/stats
  Future<Map<String, dynamic>> getStats() async {
    final r = await _dio.get('${ApiConstants.invoice}/stats');
    final body = _unwrap(r.data);
    return body is Map<String, dynamic> ? body : {};
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<InvoiceInfo> _parsePage(dynamic data) {
    final body = _unwrap(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => InvoiceInfo.fromJson(j));
    }
    if (body is List) {
      final list = body
          .map((e) => InvoiceInfo.fromJson(e as Map<String, dynamic>))
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

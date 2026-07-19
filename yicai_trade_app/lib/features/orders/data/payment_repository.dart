import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class PaymentRecord {
  final int id;
  final String paymentNo;
  final int orderId;
  final double amount;
  final String status;
  final String? paymentMethod;
  final DateTime? createdAt;

  const PaymentRecord({required this.id, required this.paymentNo, required this.orderId,
    required this.amount, required this.status, this.paymentMethod, this.createdAt});

  factory PaymentRecord.fromJson(Map<String, dynamic> json) => PaymentRecord(
    id: json['id'] ?? 0, paymentNo: json['paymentNo'] ?? '', orderId: json['orderId'] ?? 0,
    amount: (json['amount'] ?? 0).toDouble(), status: json['status'] ?? '',
    paymentMethod: json['paymentMethod'],
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null);
}

class RefundRecord {
  final int id;
  final String refundNo;
  final int orderId;
  final double amount;
  final String status;
  final String? reason;
  final DateTime? createdAt;

  const RefundRecord({required this.id, required this.refundNo, required this.orderId,
    required this.amount, required this.status, this.reason, this.createdAt});

  factory RefundRecord.fromJson(Map<String, dynamic> json) => RefundRecord(
    id: json['id'] ?? 0, refundNo: json['refundNo'] ?? '', orderId: json['orderId'] ?? 0,
    amount: (json['amount'] ?? 0).toDouble(), status: json['status'] ?? '',
    reason: json['reason'],
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null);
}

class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  Future<PaymentRecord> createPayment(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.payments, data: data);
    return PaymentRecord.fromJson(_unwrap(r.data));
  }

  Future<PaymentRecord> getPayment(int id) async {
    final r = await _dio.get('${ApiConstants.payments}/$id');
    return PaymentRecord.fromJson(_unwrap(r.data));
  }

  Future<List<PaymentRecord>> getPaymentsByOrder(int orderId) async {
    final r = await _dio.get(ApiConstants.paymentsByOrder(orderId));
    return _parseList(r.data, PaymentRecord.fromJson);
  }

  Future<PageResult<PaymentRecord>> getMyPayments({int page = 0, int size = 20}) async {
    final r = await _dio.get(ApiConstants.paymentsMy, queryParameters: {'page': page, 'size': size});
    return _parsePage(r.data, PaymentRecord.fromJson);
  }

  Future<void> confirmPayment(int id) async {
    await _dio.post('${ApiConstants.payments}/$id/confirm');
  }

  Future<void> cancelPayment(int id) async {
    await _dio.post('${ApiConstants.payments}/$id/cancel');
  }

  Future<RefundRecord> createRefund(Map<String, dynamic> data) async {
    final r = await _dio.post(ApiConstants.refunds, data: data);
    return RefundRecord.fromJson(_unwrap(r.data));
  }

  Future<PageResult<RefundRecord>> getMyRefunds({int page = 0, int size = 20}) async {
    final r = await _dio.get(ApiConstants.refundsMy, queryParameters: {'page': page, 'size': size});
    return _parsePage(r.data, RefundRecord.fromJson);
  }

  Future<List<RefundRecord>> getRefundsByOrder(int orderId) async {
    final r = await _dio.get(ApiConstants.refundsByOrder(orderId));
    return _parseList(r.data, RefundRecord.fromJson);
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data['data'] is Map<String, dynamic> ? data['data'] : data;
    return {};
  }

  List<T> _parseList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is List) return body.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    return [];
  }

  PageResult<T> _parsePage<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) return PageResult.fromJson(body, fromJson);
    final list = _parseList(data, fromJson);
    return PageResult(content: list, totalElements: list.length, totalPages: 1, pageNumber: 0, pageSize: list.length);
  }
}

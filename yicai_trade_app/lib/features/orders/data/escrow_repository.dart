import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class EscrowInfo {
  final int id;
  final int orderId;
  final double amount;
  final String status;
  final DateTime? createdAt;
  final DateTime? releaseDate;

  const EscrowInfo({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    this.createdAt,
    this.releaseDate,
  });

  factory EscrowInfo.fromJson(Map<String, dynamic> json) => EscrowInfo(
    id: json['id'] ?? 0,
    orderId: json['orderId'] ?? 0,
    amount: (json['amount'] ?? 0).toDouble(),
    status: json['status'] ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    releaseDate: json['releaseDate'] != null
        ? DateTime.tryParse(json['releaseDate'].toString())
        : null,
  );
}

/// 托管仓库 - 匹配后端 EscrowController
class EscrowRepository {
  final Dio _dio;
  EscrowRepository(this._dio);

  /// 查询订单托管信息: GET /api/escrow/order/{orderId}
  Future<EscrowInfo?> getByOrder(int orderId) async {
    try {
      final r = await _dio.get(ApiConstants.escrowByOrder(orderId));
      final body = r.data is Map<String, dynamic>
          ? (r.data['data'] ?? r.data)
          : r.data;
      if (body is Map<String, dynamic>) return EscrowInfo.fromJson(body);
    } catch (_) {}
    return null;
  }

  /// 采购商托管列表: GET /api/escrow/buyer/{buyerId}
  Future<PageResult<EscrowInfo>> getByBuyer(
    int buyerId, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      ApiConstants.escrowByBuyer(buyerId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePage(r.data);
  }

  /// 供应商托管列表: GET /api/escrow/supplier/{supplierId}
  Future<PageResult<EscrowInfo>> getBySupplier(
    int supplierId, {
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      ApiConstants.escrowBySupplier(supplierId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePage(r.data);
  }

  /// 采购商申请提前释放: POST /api/escrow/order/{orderId}/early-release
  Future<void> requestEarlyRelease(
    int orderId, {
    required int buyerId,
    String? reason,
  }) async {
    await _dio.post(
      '${ApiConstants.escrowByOrder(orderId)}/early-release',
      queryParameters: {
        'buyerId': buyerId,
        'reason': ?reason,
      },
    );
  }

  PageResult<EscrowInfo> _parsePage(dynamic data) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => EscrowInfo.fromJson(j));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => EscrowInfo.fromJson(e as Map<String, dynamic>))
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
      pageSize: 20,
    );
  }
}

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/order_model.dart';

/// 订单仓库 - 匹配后端 OrderController 端点
class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  /// 获取采购商订单列表: GET /api/orders/buyer/{buyerId}
  Future<PageResult<OrderModel>> getOrdersByBuyer(
    int buyerId, {
    String? status,
    String? keyword,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (keyword != null && keyword.isNotEmpty) params['keyword'] = keyword;

    final response = await _dio.get(
      ApiConstants.ordersByBuyer(buyerId),
      queryParameters: params,
    );
    return _parsePageResult(response.data);
  }

  /// 获取供应商订单列表: GET /api/orders/supplier/{supplierId}
  Future<PageResult<OrderModel>> getOrdersBySupplier(
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
    return _parsePageResult(response.data);
  }

  /// 获取订单详情: GET /api/orders/{id}
  Future<OrderModel> getOrderDetail(int orderId) async {
    final response = await _dio.get('${ApiConstants.orders}/$orderId');
    final body = _unwrapData(response.data);
    return OrderModel.fromJson(body as Map<String, dynamic>);
  }

  /// 创建订单: POST /api/orders?buyerId={buyerId}
  Future<OrderModel> createOrder(
    int buyerId,
    Map<String, dynamic> orderData,
  ) async {
    final response = await _dio.post(
      ApiConstants.orders,
      data: orderData,
      queryParameters: {'buyerId': buyerId},
    );
    final body = _unwrapData(response.data);
    return OrderModel.fromJson(body as Map<String, dynamic>);
  }

  /// 更新订单状态: PUT /api/orders/{id}/status
  Future<void> updateOrderStatus(
    int orderId,
    String status, {
    required int operatorId,
    String? remark,
  }) async {
    await _dio.put(
      '${ApiConstants.orders}/$orderId/status',
      data: {'status': status, 'operatorId': operatorId, 'remark': remark},
    );
  }

  /// 取消订单: POST /api/orders/{id}/cancel?operatorId={operatorId}
  Future<void> cancelOrder(int orderId, {required int operatorId}) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/cancel',
      queryParameters: {'operatorId': operatorId},
    );
  }

  /// 采购商付款: POST /api/orders/{id}/pay
  Future<void> payOrder(
    int orderId, {
    required int buyerId,
    String paymentMethod = 'ONLINE',
  }) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/pay',
      queryParameters: {
        'buyerId': buyerId,
        'paymentMethod': paymentMethod,
      },
    );
  }

  /// 供应商确认订单: POST /api/orders/{id}/confirm
  Future<void> confirmOrder(
    int orderId, {
    required int supplierId,
    String? estimatedDeliveryDate,
  }) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/confirm',
      queryParameters: {
        'supplierId': supplierId,
        'estimatedDeliveryDate': estimatedDeliveryDate,
      },
    );
  }

  /// 供应商发货: POST /api/orders/{id}/ship
  Future<void> shipOrder(
    int orderId, {
    required int supplierId,
    required String trackingNumber,
    required String logisticsCompany,
  }) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/ship',
      queryParameters: {
        'supplierId': supplierId,
        'trackingNumber': trackingNumber,
        'logisticsCompany': logisticsCompany,
      },
    );
  }

  /// 采购商确认收货: POST /api/orders/{id}/receipt
  Future<void> confirmReceipt(int orderId, {required int buyerId}) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/receipt',
      queryParameters: {'buyerId': buyerId},
    );
  }

  /// 完成订单: POST /api/orders/{id}/complete
  Future<void> completeOrder(int orderId, {required int operatorId}) async {
    await _dio.post(
      '${ApiConstants.orders}/$orderId/complete',
      queryParameters: {'operatorId': operatorId},
    );
  }

  dynamic _unwrapData(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }

  PageResult<OrderModel> _parsePageResult(dynamic data) {
    final body = _unwrapData(data);
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => OrderModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
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

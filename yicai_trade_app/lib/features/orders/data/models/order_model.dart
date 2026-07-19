import 'package:easy_localization/easy_localization.dart';

/// 订单数据模型 - 匹配后端 Order entity
class OrderModel {
  final int id;
  final String orderNo;
  final int? buyerId;
  final int? supplierId;
  final String supplierName;
  final String productName;
  final String? productImage;
  final String quantity;
  final double amount;
  final String status;
  final double progress;
  final bool hasTracking;
  final String? trackingNo;
  final String? remark;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderModel({
    required this.id,
    required this.orderNo,
    this.buyerId,
    this.supplierId,
    required this.supplierName,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.amount,
    required this.status,
    this.progress = 0,
    this.hasTracking = false,
    this.trackingNo,
    this.remark,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNo: json['orderNo'] ?? '',
      buyerId: json['buyerId'],
      supplierId: json['supplierId'],
      supplierName:
          json['supplierName'] ?? json['supplier']?['companyName'] ?? '',
      productName:
          json['productName'] ?? json['items']?[0]?['productName'] ?? '',
      productImage: json['productImage'],
      quantity: json['quantity']?.toString() ?? '',
      amount: (json['totalAmount'] ?? json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING',
      progress: (json['progress'] ?? _statusToProgress(json['status']))
          .toDouble(),
      hasTracking:
          json['trackingNo'] != null &&
          json['trackingNo'].toString().isNotEmpty,
      trackingNo: json['trackingNo'],
      remark: json['remark'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNo': orderNo,
    'buyerId': buyerId,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'productName': productName,
    'quantity': quantity,
    'totalAmount': amount,
    'status': status,
    'trackingNo': trackingNo,
    'remark': remark,
  };

  /// 状态国际化映射
  String get statusLabel => _statusLabelsMap[status] ?? status;

  static Map<String, String> get _statusLabelsMap => {
    'PENDING': 'order.status_pending'.tr(),
    'CONFIRMED': 'order.status_confirmed'.tr(),
    'IN_PRODUCTION': 'order.status_in_production'.tr(),
    'SHIPPED': 'order.status_shipped'.tr(),
    'RECEIVED': 'order.status_received'.tr(),
    'COMPLETED': 'order.status_completed'.tr(),
    'CANCELLED': 'order.status_cancelled'.tr(),
  };

  /// 状态映射到进度值
  static double _statusToProgress(String? status) {
    switch (status) {
      case 'PENDING':
        return 0.0;
      case 'CONFIRMED':
        return 0.2;
      case 'IN_PRODUCTION':
        return 0.5;
      case 'SHIPPED':
        return 0.8;
      case 'RECEIVED':
        return 0.9;
      case 'COMPLETED':
        return 1.0;
      default:
        return 0.0;
    }
  }
}

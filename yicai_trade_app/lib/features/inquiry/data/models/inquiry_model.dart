import 'package:easy_localization/easy_localization.dart';

/// 询盘数据模型 - 匹配后端 Inquiry entity
class InquiryModel {
  final int id;
  final String productName;
  final String supplierName;
  final int? supplierId;
  final String quantity;
  final String status;
  final double? quotedPrice;
  final String? deliveryDays;
  final String? description;
  final int? buyerId;
  final DateTime? createdAt;

  const InquiryModel({
    required this.id,
    required this.productName,
    required this.supplierName,
    this.supplierId,
    required this.quantity,
    required this.status,
    this.quotedPrice,
    this.deliveryDays,
    this.description,
    this.buyerId,
    this.createdAt,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? json['title'] ?? '',
      supplierName: json['supplierName'] ?? '',
      supplierId: json['supplierId'],
      quantity: json['quantity']?.toString() ?? '',
      status: json['status'] ?? 'PENDING',
      quotedPrice: json['quotedPrice'] != null
          ? (json['quotedPrice'] as num).toDouble()
          : null,
      deliveryDays: json['deliveryDays']?.toString(),
      description: json['description'],
      buyerId: json['buyerId'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'productName': productName,
    'supplierId': supplierId,
    'quantity': quantity,
    'description': description,
  };

  String get statusLabel => _statusLabelsMap[status] ?? status;

  static Map<String, String> get _statusLabelsMap => {
    'PENDING': 'inquiry.status_pending'.tr(),
    'QUOTED': 'inquiry.status_quoted'.tr(),
    'CLOSED': 'inquiry.status_closed'.tr(),
    'ACCEPTED': 'inquiry.status_accepted'.tr(),
  };
}

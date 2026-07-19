import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// 合同数据模型 - 匹配后端 Contract entity
class ContractModel {
  final int id;
  final String contractNo;
  final String title;
  final String partnerName;
  final String buyerName;
  final String supplierName;
  final double amount;
  final String period;
  final String status;
  final int? orderId;
  final int? buyerId;
  final int? supplierId;
  final String? fileUrl;
  final String? paymentTerms;
  final String? deliveryTerms;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? signedAt;
  final DateTime? createdAt;

  const ContractModel({
    required this.id,
    required this.contractNo,
    required this.title,
    required this.partnerName,
    this.buyerName = '',
    this.supplierName = '',
    required this.amount,
    required this.period,
    required this.status,
    this.orderId,
    this.buyerId,
    this.supplierId,
    this.fileUrl,
    this.paymentTerms,
    this.deliveryTerms,
    this.startDate,
    this.endDate,
    this.signedAt,
    this.createdAt,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] ?? 0,
      contractNo: json['contractNo'] ?? '',
      title: json['title'] ?? '',
      partnerName: json['partnerName'] ?? json['supplierName'] ?? '',
      buyerName: json['buyerName'] ?? '',
      supplierName: json['supplierName'] ?? json['partnerName'] ?? '',
      amount: (json['amount'] ?? json['totalAmount'] ?? 0).toDouble(),
      period: json['period'] ?? _buildPeriod(json),
      status: json['status'] ?? 'PENDING',
      orderId: json['orderId'],
      buyerId: json['buyerId'],
      supplierId: json['supplierId'],
      fileUrl: json['fileUrl'],
      paymentTerms: json['paymentTerms'],
      deliveryTerms: json['deliveryTerms'],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      signedAt: json['signedAt'] != null
          ? DateTime.tryParse(json['signedAt'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  static String _buildPeriod(Map<String, dynamic> json) {
    final start = json['startDate'] ?? json['effectiveDate'];
    final end = json['endDate'] ?? json['expiryDate'];
    if (start != null && end != null) return '$start - $end';
    if (json['status'] == 'PENDING_SIGN') {
      return 'contract.pending_sign_effect'.tr();
    }
    return '';
  }

  /// 状态国际化标签
  String get statusLabel => _statusLabelsMap[status] ?? status;

  /// 状态颜色
  Color get statusColor {
    switch (status) {
      case 'PENDING_SIGN':
        return AppColors.warning;
      case 'ACTIVE':
        return AppColors.success;
      case 'COMPLETED':
        return AppColors.featureTeal;
      case 'EXPIRED':
        return AppColors.textSecondary;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  static Map<String, String> get _statusLabelsMap => {
    'PENDING_SIGN': 'contract.status_pending_sign'.tr(),
    'ACTIVE': 'contract.status_active'.tr(),
    'COMPLETED': 'contract.status_completed'.tr(),
    'EXPIRED': 'contract.status_expired'.tr(),
    'CANCELLED': 'contract.status_cancelled'.tr(),
  };
}

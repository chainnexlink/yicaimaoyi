import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

/// 认证状态模型 - 对标网站 certification.html 的完整数据结构
class CertificationModel {
  final int id;
  final String? certNo;
  final String type;
  final String status;

  // 企业信息
  final String? companyName;
  final String? creditCode;
  final String? companyType;
  final String? registeredCapital;
  final String? foundDate;
  final String? companyAddress;

  // 法人信息
  final String? legalName;
  final String? legalIdNumber;
  final String? legalPhone;
  final String? legalIdFront;
  final String? legalIdBack;

  // 证照
  final String? businessLicense;
  final List<String> otherCerts;

  // 联系人
  final String? contactName;
  final String? contactTitle;
  final String? contactPhone;
  final String? contactEmail;

  // 审核信息
  final String? remark;
  final String? auditedBy;
  final DateTime? createdAt;
  final DateTime? auditedAt;
  final DateTime? expireAt;

  const CertificationModel({
    required this.id,
    this.certNo,
    required this.type,
    required this.status,
    this.companyName,
    this.creditCode,
    this.companyType,
    this.registeredCapital,
    this.foundDate,
    this.companyAddress,
    this.legalName,
    this.legalIdNumber,
    this.legalPhone,
    this.legalIdFront,
    this.legalIdBack,
    this.businessLicense,
    this.otherCerts = const [],
    this.contactName,
    this.contactTitle,
    this.contactPhone,
    this.contactEmail,
    this.remark,
    this.auditedBy,
    this.createdAt,
    this.auditedAt,
    this.expireAt,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) {
    return CertificationModel(
      id: json['id'] ?? 0,
      certNo: json['certNo'],
      type: json['type'] ?? '',
      status: json['status'] ?? 'PENDING',
      companyName: json['companyName'],
      creditCode: json['creditCode'],
      companyType: json['companyType'],
      registeredCapital: json['registeredCapital'],
      foundDate: json['foundDate'],
      companyAddress: json['companyAddress'],
      legalName: json['legalName'],
      legalIdNumber: json['legalIdNumber'],
      legalPhone: json['legalPhone'],
      legalIdFront: json['legalIdFront'],
      legalIdBack: json['legalIdBack'],
      businessLicense: json['businessLicense'],
      otherCerts: json['otherCerts'] is List
          ? (json['otherCerts'] as List).map((e) => e.toString()).toList()
          : const [],
      contactName: json['contactName'],
      contactTitle: json['contactTitle'],
      contactPhone: json['contactPhone'],
      contactEmail: json['contactEmail'],
      remark: json['remark'],
      auditedBy: json['auditedBy'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      auditedAt: json['auditedAt'] != null
          ? DateTime.tryParse(json['auditedAt'].toString())
          : null,
      expireAt: json['expireAt'] != null
          ? DateTime.tryParse(json['expireAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    if (companyName != null) 'companyName': companyName,
    if (creditCode != null) 'creditCode': creditCode,
    if (companyType != null) 'companyType': companyType,
    if (registeredCapital != null) 'registeredCapital': registeredCapital,
    if (foundDate != null) 'foundDate': foundDate,
    if (companyAddress != null) 'companyAddress': companyAddress,
    if (legalName != null) 'legalName': legalName,
    if (legalIdNumber != null) 'legalIdNumber': legalIdNumber,
    if (legalPhone != null) 'legalPhone': legalPhone,
    if (businessLicense != null) 'businessLicense': businessLicense,
    if (otherCerts.isNotEmpty) 'otherCerts': otherCerts,
    if (contactName != null) 'contactName': contactName,
    if (contactTitle != null) 'contactTitle': contactTitle,
    if (contactPhone != null) 'contactPhone': contactPhone,
    if (contactEmail != null) 'contactEmail': contactEmail,
  };

  String get statusLabel {
    final m = {
      'PENDING': 'certification.status_pending'.tr(),
      'APPROVED': 'certification.status_approved'.tr(),
      'REJECTED': 'certification.status_rejected'.tr(),
      'EXPIRED': 'certification.status_expired'.tr(),
    };
    return m[status] ?? status;
  }

  Color get statusColor {
    switch (status) {
      case 'APPROVED':
        return AppColors.success;
      case 'REJECTED':
        return AppColors.error;
      case 'EXPIRED':
        return AppColors.textSecondary;
      default:
        return AppColors.warning;
    }
  }

  bool get isApproved => status == 'APPROVED';
  bool get isPending => status == 'PENDING';
  bool get isRejected => status == 'REJECTED';
  bool get isExpired =>
      status == 'EXPIRED' ||
      (expireAt != null && expireAt!.isBefore(DateTime.now()));
}

/// 认证统计概览
class CertificationStats {
  final int totalApproved;
  final int totalPending;
  final String? creditLevel;
  final double? trustScore;

  const CertificationStats({
    this.totalApproved = 0,
    this.totalPending = 0,
    this.creditLevel,
    this.trustScore,
  });

  factory CertificationStats.fromJson(Map<String, dynamic> json) {
    return CertificationStats(
      totalApproved: json['totalApproved'] ?? 0,
      totalPending: json['totalPending'] ?? 0,
      creditLevel: json['creditLevel'],
      trustScore: (json['trustScore'] as num?)?.toDouble(),
    );
  }
}

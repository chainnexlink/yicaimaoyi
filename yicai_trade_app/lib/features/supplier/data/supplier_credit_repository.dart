import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';

/// 供应商信用模型
class SupplierCreditInfo {
  final int supplierId;
  final String supplierName;
  final double creditScore;
  final String creditLevel; // A, B, C, D
  final int totalOrders;
  final int completedOrders;
  final double onTimeRate;
  final double qualityRate;
  final DateTime? lastUpdated;

  const SupplierCreditInfo({
    required this.supplierId,
    required this.supplierName,
    required this.creditScore,
    required this.creditLevel,
    this.totalOrders = 0,
    this.completedOrders = 0,
    this.onTimeRate = 0,
    this.qualityRate = 0,
    this.lastUpdated,
  });

  factory SupplierCreditInfo.fromJson(Map<String, dynamic> json) =>
      SupplierCreditInfo(
        supplierId: json['supplierId'] ?? 0,
        supplierName: json['supplierName'] ?? '',
        creditScore: (json['creditScore'] ?? json['score'] ?? 0).toDouble(),
        creditLevel: json['creditLevel'] ?? json['level'] ?? 'C',
        totalOrders: json['totalOrders'] ?? 0,
        completedOrders: json['completedOrders'] ?? 0,
        onTimeRate: (json['onTimeRate'] ?? 0).toDouble(),
        qualityRate: (json['qualityRate'] ?? 0).toDouble(),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.tryParse(json['lastUpdated'].toString())
            : null,
      );

  String get levelLabel {
    final labels = {
      'A': 'supplier.credit_excellent'.tr(),
      'B': 'supplier.credit_good'.tr(),
      'C': 'supplier.credit_average'.tr(),
      'D': 'supplier.credit_poor'.tr(),
    };
    return labels[creditLevel] ?? creditLevel;
  }
}

/// 信用变更记录
class CreditChangeLog {
  final int id;
  final String changeType;
  final double oldScore;
  final double newScore;
  final String reason;
  final DateTime? createdAt;

  const CreditChangeLog({
    required this.id,
    required this.changeType,
    required this.oldScore,
    required this.newScore,
    required this.reason,
    this.createdAt,
  });

  factory CreditChangeLog.fromJson(Map<String, dynamic> json) =>
      CreditChangeLog(
        id: json['id'] ?? 0,
        changeType: json['changeType'] ?? '',
        oldScore: (json['oldScore'] ?? 0).toDouble(),
        newScore: (json['newScore'] ?? 0).toDouble(),
        reason: json['reason'] ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );
}

/// 供应商信用仓库 - 匹配后端 SupplierCreditController (/api/supplier-credit)
class SupplierCreditRepository {
  final Dio _dio;
  SupplierCreditRepository(this._dio);

  /// 获取供应商信用: GET /api/supplier-credit/supplier/{supplierId}
  Future<SupplierCreditInfo> getCredit(int supplierId) async {
    final r = await _dio.get(
      '${ApiConstants.supplierCredit}/supplier/$supplierId',
    );
    final body = _unwrap(r.data);
    return SupplierCreditInfo.fromJson(body as Map<String, dynamic>);
  }

  /// 获取信用排名: GET /api/supplier-credit/ranking
  Future<List<SupplierCreditInfo>> getRanking({
    int page = 0,
    int size = 20,
  }) async {
    final r = await _dio.get(
      '${ApiConstants.supplierCredit}/ranking',
      queryParameters: {'page': page, 'size': size},
    );
    final body = _unwrap(r.data);
    List items;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      items = body['content'] as List;
    } else if (body is List) {
      items = body;
    } else {
      return [];
    }
    return items
        .map((e) => SupplierCreditInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取变更日志: GET /api/supplier-credit/supplier/{supplierId}/changelog
  Future<List<CreditChangeLog>> getChangeLog(int supplierId) async {
    final r = await _dio.get(
      '${ApiConstants.supplierCredit}/supplier/$supplierId/changelog',
    );
    final body = _unwrap(r.data);
    if (body is List) {
      return body
          .map((e) => CreditChangeLog.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  dynamic _unwrap(dynamic data) {
    if (data is Map<String, dynamic> && data.containsKey('data')) {
      return data['data'];
    }
    return data;
  }
}

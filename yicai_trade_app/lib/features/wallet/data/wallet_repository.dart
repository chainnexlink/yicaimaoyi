import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';

class WalletInfo {
  final int id;
  final String ownerType;
  final int ownerId;
  final double balance;
  final double frozenAmount;
  final String status;

  const WalletInfo({required this.id, required this.ownerType, required this.ownerId,
    required this.balance, this.frozenAmount = 0, this.status = 'ACTIVE'});

  factory WalletInfo.fromJson(Map<String, dynamic> json) => WalletInfo(
    id: json['id'] ?? 0, ownerType: json['ownerType'] ?? '',
    ownerId: json['ownerId'] ?? 0, balance: (json['balance'] ?? 0).toDouble(),
    frozenAmount: (json['frozenAmount'] ?? 0).toDouble(), status: json['status'] ?? 'ACTIVE');
}

class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String? description;
  final DateTime? createdAt;

  const WalletTransaction({required this.id, required this.type, required this.amount,
    required this.balanceAfter, this.description, this.createdAt});

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
    id: json['id'] ?? 0, type: json['type'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(), balanceAfter: (json['balanceAfter'] ?? 0).toDouble(),
    description: json['description'],
    createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null);

  String get typeLabel {
    final labels = {
      'RECHARGE': 'wallet.type_recharge'.tr(),
      'WITHDRAW': 'wallet.type_withdraw'.tr(),
      'PAYMENT': 'wallet.type_payment'.tr(),
      'REFUND': 'wallet.type_refund'.tr(),
      'COMMISSION': 'wallet.type_commission'.tr(),
      'REBATE': 'wallet.type_rebate'.tr(),
    };
    return labels[type] ?? type;
  }

  bool get isIncome => ['RECHARGE', 'REFUND', 'REBATE'].contains(type);
}

class WalletRepository {
  final Dio _dio;
  WalletRepository(this._dio);

  Future<WalletInfo> getWallet(String ownerType, int ownerId) async {
    final r = await _dio.get(ApiConstants.walletGet(ownerType, ownerId));
    return WalletInfo.fromJson(_unwrap(r.data));
  }

  Future<PageResult<WalletTransaction>> getTransactions(
    String ownerType, int ownerId, {int page = 0, int size = 20}) async {
    final r = await _dio.get(ApiConstants.walletTransactions(ownerType, ownerId),
      queryParameters: {'page': page, 'size': size});
    return _parsePage(r.data);
  }

  Future<void> recharge(String ownerType, int ownerId, double amount) async {
    await _dio.post(ApiConstants.walletRecharge(ownerType, ownerId), data: {'amount': amount});
  }

  Future<void> withdraw(String ownerType, int ownerId, double amount) async {
    await _dio.post(ApiConstants.walletWithdraw(ownerType, ownerId), data: {'amount': amount});
  }

  Map<String, dynamic> _unwrap(dynamic data) {
    if (data is Map<String, dynamic>) return data['data'] is Map<String, dynamic> ? data['data'] : data;
    return {};
  }

  PageResult<WalletTransaction> _parsePage(dynamic data) {
    final body = data is Map<String, dynamic> ? (data['data'] ?? data) : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (j) => WalletTransaction.fromJson(j));
    }
    if (body is List) {
      return PageResult(content: body.map((e) => WalletTransaction.fromJson(e)).toList(),
        totalElements: body.length, totalPages: 1, pageNumber: 0, pageSize: body.length);
    }
    return const PageResult(content: [], totalElements: 0, totalPages: 0, pageNumber: 0, pageSize: 20);
  }
}

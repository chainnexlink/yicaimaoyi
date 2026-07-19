import 'package:easy_localization/easy_localization.dart';

/// 竞价数据模型 - 匹配后端 Auction entity + 网站 auction-detail.html
class AuctionModel {
  final int id;
  final String title;
  final String status;
  final int bidderCount;
  final double? currentLowest;
  final String quantity;
  final double targetPrice;
  final String? description;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> tags;
  final int? creatorId;
  final DateTime? createdAt;

  // 网站版新增字段
  final String? auctionNo;
  final String? productName;
  final String? productCategory;
  final String? specification;
  final String? unit;
  final double? startingPrice;
  final double? minDecrement;
  final DateTime? signupStartTime;
  final DateTime? signupEndTime;
  final int minParticipants;
  final int extensionTriggerMinutes;
  final int extensionMinutes;
  final int maxExtensions;
  final int currentExtensions;
  final bool showRanking;
  final bool showLowestPrice;
  final String? deliveryAddress;
  final String? requiredDeliveryDate;
  final String? paymentTerms;
  final String? remark;
  final int signupCount;
  final int bidCount;
  final bool? buyerConfirmed;
  final bool? supplierConfirmed;
  final DateTime? confirmDeadline;
  final int? winnerId;
  final String? winnerName;

  const AuctionModel({
    required this.id,
    required this.title,
    required this.status,
    this.bidderCount = 0,
    this.currentLowest,
    required this.quantity,
    required this.targetPrice,
    this.description,
    this.startTime,
    this.endTime,
    this.tags = const [],
    this.creatorId,
    this.createdAt,
    this.auctionNo,
    this.productName,
    this.productCategory,
    this.specification,
    this.unit,
    this.startingPrice,
    this.minDecrement,
    this.signupStartTime,
    this.signupEndTime,
    this.minParticipants = 3,
    this.extensionTriggerMinutes = 5,
    this.extensionMinutes = 5,
    this.maxExtensions = 10,
    this.currentExtensions = 0,
    this.showRanking = true,
    this.showLowestPrice = true,
    this.deliveryAddress,
    this.requiredDeliveryDate,
    this.paymentTerms,
    this.remark,
    this.signupCount = 0,
    this.bidCount = 0,
    this.buyerConfirmed,
    this.supplierConfirmed,
    this.confirmDeadline,
    this.winnerId,
    this.winnerName,
  });

  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['productName'] ?? '',
      status: json['status'] ?? 'DRAFT',
      bidderCount: json['bidderCount'] ?? json['participantCount'] ?? 0,
      currentLowest: json['currentLowest'] != null
          ? (json['currentLowest'] as num).toDouble()
          : json['currentLowestPrice'] != null
          ? (json['currentLowestPrice'] as num).toDouble()
          : null,
      quantity: json['quantity']?.toString() ?? '',
      targetPrice: (json['targetPrice'] ?? json['budgetPrice'] ?? 0).toDouble(),
      description: json['description'],
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      tags:
          (json['tags'] as List<dynamic>?)?.cast<String>() ??
          (json['category'] != null ? [json['category'].toString()] : []),
      creatorId: json['creatorId'],
      createdAt: _parseDateTime(json['createdAt']),
      auctionNo: json['auctionNo'],
      productName: json['productName'],
      productCategory: json['productCategory'],
      specification: json['specification'],
      unit: json['unit'],
      startingPrice: _parseDouble(json['startingPrice']),
      minDecrement: _parseDouble(json['minDecrement']),
      signupStartTime: _parseDateTime(json['signupStartTime']),
      signupEndTime: _parseDateTime(json['signupEndTime']),
      minParticipants: json['minParticipants'] ?? 3,
      extensionTriggerMinutes: json['extensionTriggerMinutes'] ?? 5,
      extensionMinutes: json['extensionMinutes'] ?? 5,
      maxExtensions: json['maxExtensions'] ?? 10,
      currentExtensions: json['currentExtensions'] ?? 0,
      showRanking: json['showRanking'] ?? true,
      showLowestPrice: json['showLowestPrice'] ?? true,
      deliveryAddress: json['deliveryAddress'],
      requiredDeliveryDate: json['requiredDeliveryDate'],
      paymentTerms: json['paymentTerms'],
      remark: json['remark'],
      signupCount: json['signupCount'] ?? 0,
      bidCount: json['bidCount'] ?? 0,
      buyerConfirmed: json['buyerConfirmed'],
      supplierConfirmed: json['supplierConfirmed'],
      confirmDeadline: _parseDateTime(json['confirmDeadline']),
      winnerId: json['winnerId'],
      winnerName: json['winnerName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    if (productName != null) 'productName': productName,
    if (productCategory != null) 'productCategory': productCategory,
    if (specification != null) 'specification': specification,
    'quantity': quantity,
    if (unit != null) 'unit': unit,
    'targetPrice': targetPrice,
    if (startingPrice != null) 'startingPrice': startingPrice,
    if (minDecrement != null) 'minDecrement': minDecrement,
    'description': description,
    'startTime': startTime?.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    if (signupStartTime != null)
      'signupStartTime': signupStartTime!.toIso8601String(),
    if (signupEndTime != null)
      'signupEndTime': signupEndTime!.toIso8601String(),
    'minParticipants': minParticipants,
    'extensionTriggerMinutes': extensionTriggerMinutes,
    'extensionMinutes': extensionMinutes,
    'maxExtensions': maxExtensions,
    'showRanking': showRanking,
    'showLowestPrice': showLowestPrice,
    if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    if (requiredDeliveryDate != null)
      'requiredDeliveryDate': requiredDeliveryDate,
    if (paymentTerms != null) 'paymentTerms': paymentTerms,
    if (remark != null) 'remark': remark,
    'tags': tags,
  };

  /// 状态中文
  String get statusLabel => _statusLabelsMap[status] ?? status;

  static Map<String, String> get _statusLabelsMap => {
    'DRAFT': 'auction.status_draft'.tr(),
    'PENDING_APPROVAL': 'auction.status_pending_approval'.tr(),
    'APPROVED': 'auction.status_approved'.tr(),
    'SIGNUP': 'auction.status_signup'.tr(),
    'PUBLISHED': 'auction.status_published'.tr(),
    'PENDING': 'auction.status_pending'.tr(),
    'ACTIVE': 'auction.status_active'.tr(),
    'BIDDING': 'auction.status_bidding'.tr(),
    'CONFIRMING': 'auction.status_confirming'.tr(),
    'CONFIRMED': 'auction.status_confirmed'.tr(),
    'DELIVERING': 'auction.status_delivering'.tr(),
    'COMPLETED': 'auction.status_completed'.tr(),
    'ENDED': 'auction.status_ended'.tr(),
    'FAILED': 'auction.status_failed'.tr(),
    'CLOSED': 'auction.status_closed'.tr(),
    'CANCELLED': 'auction.status_cancelled'.tr(),
    'VOIDED': 'auction.status_voided'.tr(),
  };

  /// 竞价中状态
  bool get isActive => status == 'ACTIVE' || status == 'BIDDING';

  /// 报名阶段
  bool get isSignup => status == 'SIGNUP' || status == 'APPROVED';

  /// 待确认
  bool get isConfirming => status == 'CONFIRMING';

  /// 有效最高限价
  double get effectiveStartingPrice => startingPrice ?? targetPrice;

  /// 计算剩余时间
  String get timeLeftDisplay {
    if (endTime == null) return '';
    final now = DateTime.now();
    if (isActive && endTime!.isAfter(now)) {
      final diff = endTime!.difference(now);
      if (diff.inHours > 0) return '${diff.inHours}${'common.hours'.tr()}${diff.inMinutes % 60}${'common.minutes'.tr()}';
      return '${diff.inMinutes}${'common.minutes'.tr()}';
    }
    if ((status == 'PUBLISHED' || status == 'PENDING') && startTime != null) {
      return '${startTime!.month}${'common.month_unit'.tr()}${startTime!.day}${'common.day_unit'.tr()} ${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')} ${'common.start'.tr()}';
    }
    if (endTime!.isBefore(now)) {
      return '${endTime!.month}${'common.month_unit'.tr()}${endTime!.day}${'common.day_unit'.tr()} ${'common.finish'.tr()}';
    }
    return '';
  }

  /// Tab筛选映射
  static String? tabToApiStatus(String tab) {
    const map = {'ALL': null, 'BIDDING': 'BIDDING', 'PUBLISHED': 'PUBLISHED', 'CLOSED': 'CLOSED'};
    return map[tab];
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

/// 竞价出价模型
class BidModel {
  final int id;
  final int auctionId;
  final int supplierId;
  final String supplierName;
  final double price;
  final DateTime? createdAt;
  // 网站版新增字段
  final String? supplierCompany;
  final int? bidSequence;
  final bool? isLowest;
  final bool? isWinner;

  const BidModel({
    required this.id,
    required this.auctionId,
    required this.supplierId,
    required this.supplierName,
    required this.price,
    this.createdAt,
    this.supplierCompany,
    this.bidSequence,
    this.isLowest,
    this.isWinner,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      id: json['id'] ?? 0,
      auctionId: json['auctionId'] ?? 0,
      supplierId: json['supplierId'] ?? 0,
      supplierName: json['supplierName'] ?? json['supplierCompany'] ?? '',
      price: (json['price'] ?? json['bidPrice'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      supplierCompany: json['supplierCompany'],
      bidSequence: json['bidSequence'],
      isLowest: json['isLowest'],
      isWinner: json['isWinner'],
    );
  }
}

/// 押金信息模型
class DepositInfo {
  final double amount;
  final String status; // UNPAID, PAID, REFUNDED
  final String? voucherId;

  const DepositInfo({
    required this.amount,
    required this.status,
    this.voucherId,
  });

  bool get isPaid => status == 'PAID';

  factory DepositInfo.fromJson(Map<String, dynamic> json) {
    return DepositInfo(
      amount: (json['amount'] ?? json['depositAmount'] ?? 0).toDouble(),
      status: json['status'] ?? json['depositStatus'] ?? 'UNPAID',
      voucherId: json['voucherId'],
    );
  }

  factory DepositInfo.unpaid({double amount = 50.0}) {
    return DepositInfo(amount: amount, status: 'UNPAID');
  }
}

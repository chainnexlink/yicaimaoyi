// 生产监控数据模型 - 匹配后端 Monitor entity + 网站 production-monitor.html
import 'package:easy_localization/easy_localization.dart';

/// 生产监控主模型
class MonitorModel {
  final int id;
  final int orderId;
  final String orderNo;
  final String productName;
  final String supplierName;
  final double progress;
  final bool hasAlert;
  final String? alertMessage;
  final List<TimelineNode> timeline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // 网站版扩展字段
  final String? status; // PRODUCING, QC, SHIPPING, COMPLETED
  final int? quantity;
  final String? currentStage;
  final DateTime? expectedDelivery;
  final double? qualityScore;

  const MonitorModel({
    required this.id,
    required this.orderId,
    required this.orderNo,
    required this.productName,
    required this.supplierName,
    this.progress = 0,
    this.hasAlert = false,
    this.alertMessage,
    this.timeline = const [],
    this.createdAt,
    this.updatedAt,
    this.status,
    this.quantity,
    this.currentStage,
    this.expectedDelivery,
    this.qualityScore,
  });

  factory MonitorModel.fromJson(Map<String, dynamic> json) {
    return MonitorModel(
      id: json['id'] ?? 0,
      orderId: json['orderId'] ?? 0,
      orderNo: json['orderNo'] ?? '',
      productName: json['productName'] ?? '',
      supplierName: json['supplierName'] ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
      hasAlert: json['hasAlert'] ?? json['alertLevel'] == 'WARNING',
      alertMessage: json['alertMessage'],
      timeline:
          (json['timeline'] as List<dynamic>?)
              ?.map((e) => TimelineNode.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      status: json['status'],
      quantity: json['quantity'],
      currentStage: json['currentStage'],
      expectedDelivery: _parseDateTime(json['expectedDelivery']),
      qualityScore: json['qualityScore'] != null
          ? (json['qualityScore'] as num).toDouble()
          : null,
    );
  }

  String get statusLabel {
    final labels = {
      'PRODUCING': 'monitor.status_producing'.tr(),
      'QC': 'monitor.status_qc'.tr(),
      'SHIPPING': 'monitor.status_shipping'.tr(),
      'COMPLETED': 'monitor.status_completed'.tr(),
      'DELAYED': 'monitor.status_delayed'.tr(),
    };
    return labels[status] ?? status ?? 'common.unknown'.tr();
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

/// 时间线节点
class TimelineNode {
  final String label;
  final String time;
  final bool completed;
  final String? status;

  const TimelineNode({
    required this.label,
    required this.time,
    this.completed = false,
    this.status,
  });

  factory TimelineNode.fromJson(Map<String, dynamic> json) {
    return TimelineNode(
      label: json['label'] ?? json['stageName'] ?? '',
      time: json['time'] ?? json['completedAt'] ?? json['expectedAt'] ?? '',
      completed: json['completed'] ?? json['status'] == 'COMPLETED',
      status: json['status'],
    );
  }
}

/// 生产监控统计
class MonitorStats {
  final int monitoring;
  final int completed;
  final int alerts;
  final String qualityRate;

  const MonitorStats({
    this.monitoring = 0,
    this.completed = 0,
    this.alerts = 0,
    this.qualityRate = '0%',
  });

  factory MonitorStats.fromJson(Map<String, dynamic> json) {
    return MonitorStats(
      monitoring: json['monitoring'] ?? json['inProgress'] ?? 0,
      completed: json['completed'] ?? 0,
      alerts: json['alerts'] ?? json['warningCount'] ?? 0,
      qualityRate: json['qualityRate']?.toString() ?? '0%',
    );
  }
}

/// KPI 数据 (匹配网站 dashboard-kpi-row)
class KpiData {
  final int totalOrders;
  final int producing;
  final int completed;
  final int shipping;
  final int pendingAlerts;
  final int suppliers;
  final double deliveryRate;
  final double avgSupplierScore;

  const KpiData({
    this.totalOrders = 0,
    this.producing = 0,
    this.completed = 0,
    this.shipping = 0,
    this.pendingAlerts = 0,
    this.suppliers = 0,
    this.deliveryRate = 0,
    this.avgSupplierScore = 0,
  });

  factory KpiData.fromJson(Map<String, dynamic> json) {
    return KpiData(
      totalOrders: json['totalOrders'] ?? json['total'] ?? 0,
      producing: json['producing'] ?? json['inProduction'] ?? 0,
      completed: json['completed'] ?? 0,
      shipping: json['shipping'] ?? json['inTransit'] ?? 0,
      pendingAlerts: json['pendingAlerts'] ?? json['alerts'] ?? 0,
      suppliers: json['suppliers'] ?? json['supplierCount'] ?? 0,
      deliveryRate: (json['deliveryRate'] ?? json['onTimeRate'] ?? 0)
          .toDouble(),
      avgSupplierScore: (json['avgSupplierScore'] ?? 0).toDouble(),
    );
  }
}

/// 周趋势数据点
class WeeklyTrendPoint {
  final String day; // "周一", "Mon", etc.
  final int value;

  const WeeklyTrendPoint({required this.day, required this.value});

  factory WeeklyTrendPoint.fromJson(Map<String, dynamic> json) {
    return WeeklyTrendPoint(
      day: json['day'] ?? json['label'] ?? '',
      value: json['value'] ?? json['count'] ?? 0,
    );
  }
}

/// 预警项
class AlertItem {
  final int id;
  final String type; // DELAY, QUALITY, MATERIAL, CAPACITY
  final String level; // HIGH, MEDIUM, LOW
  final String title;
  final String description;
  final String orderNo;
  final String supplierName;
  final String status; // PENDING, PROCESSING, RESOLVED
  final DateTime? createdAt;

  const AlertItem({
    required this.id,
    required this.type,
    required this.level,
    required this.title,
    required this.description,
    required this.orderNo,
    required this.supplierName,
    this.status = 'PENDING',
    this.createdAt,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? json['alertType'] ?? 'DELAY',
      level: json['level'] ?? json['alertLevel'] ?? 'MEDIUM',
      title: json['title'] ?? json['alertTitle'] ?? '',
      description: json['description'] ?? json['alertMessage'] ?? '',
      orderNo: json['orderNo'] ?? '',
      supplierName: json['supplierName'] ?? '',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  bool get isHigh => level == 'HIGH';
  bool get isPending => status == 'PENDING';

  String get levelLabel {
    final labels = {
      'HIGH': 'monitor.risk_high'.tr(),
      'MEDIUM': 'monitor.risk_medium'.tr(),
      'LOW': 'monitor.risk_low'.tr(),
    };
    return labels[level] ?? level;
  }

  String get typeLabel {
    final labels = {
      'DELAY': 'monitor.alert_delay'.tr(),
      'QUALITY': 'monitor.alert_quality'.tr(),
      'MATERIAL': 'monitor.alert_material'.tr(),
      'CAPACITY': 'monitor.alert_capacity'.tr(),
    };
    return labels[type] ?? type;
  }
}

/// 供应商评分
class SupplierScore {
  final int id;
  final String name;
  final double overallScore;
  final double qualityScore;
  final double deliveryScore;
  final double serviceScore;
  final int orderCount;
  final int completedOrders;
  final String? trend; // UP, DOWN, STABLE

  const SupplierScore({
    required this.id,
    required this.name,
    this.overallScore = 0,
    this.qualityScore = 0,
    this.deliveryScore = 0,
    this.serviceScore = 0,
    this.orderCount = 0,
    this.completedOrders = 0,
    this.trend,
  });

  factory SupplierScore.fromJson(Map<String, dynamic> json) {
    return SupplierScore(
      id: json['id'] ?? json['supplierId'] ?? 0,
      name: json['name'] ?? json['supplierName'] ?? '',
      overallScore: (json['overallScore'] ?? json['score'] ?? 0).toDouble(),
      qualityScore: (json['qualityScore'] ?? 0).toDouble(),
      deliveryScore: (json['deliveryScore'] ?? 0).toDouble(),
      serviceScore: (json['serviceScore'] ?? 0).toDouble(),
      orderCount: json['orderCount'] ?? 0,
      completedOrders: json['completedOrders'] ?? 0,
      trend: json['trend'],
    );
  }
}

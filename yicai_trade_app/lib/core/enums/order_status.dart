import 'package:easy_localization/easy_localization.dart';

/// 订单状态枚举 - 匹配后端 OrderStatus
enum OrderStatus {
  pending('PENDING', 'Pending'),
  confirmed('CONFIRMED', 'Confirmed'),
  paid('PAID', 'Paid'),
  production('PRODUCTION', 'In Production'),
  shipped('SHIPPED', 'Shipped'),
  received('RECEIVED', 'Received'),
  completed('COMPLETED', 'Completed'),
  cancelled('CANCELLED', 'Cancelled');

  const OrderStatus(this.value, this.label);
  final String value;
  final String label;

  /// 国际化标签
  String get localizedLabel => 'order.status_$name'.tr();

  static OrderStatus fromValue(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => OrderStatus.pending,
    );
  }
}

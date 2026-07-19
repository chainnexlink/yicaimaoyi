import 'package:easy_localization/easy_localization.dart';

/// 用户角色枚举 - 匹配后端 UserRoleEnum
enum UserRole {
  buyer('BUYER', 'Buyer'),
  supplier('SUPPLIER', 'Supplier'),
  admin('ADMIN', 'Admin');

  const UserRole(this.value, this.label);
  final String value;
  final String label;

  /// 国际化标签
  String get localizedLabel => 'common.role_$name'.tr();

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => UserRole.buyer,
    );
  }
}

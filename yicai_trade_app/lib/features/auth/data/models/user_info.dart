import 'dart:convert';

/// 用户基本信息模型 - 匹配后端 User entity 核心字段
class UserInfo {
  final int id;
  final String username;
  final String? email;
  final String? phone;
  final String? realName;
  final String? avatarUrl;
  final String userType;
  final String? status;
  final String? companyName;

  const UserInfo({
    required this.id,
    required this.username,
    this.email,
    this.phone,
    this.realName,
    this.avatarUrl,
    required this.userType,
    this.status,
    this.companyName,
  });

  /// 显示名称优先级: realName > username
  String get displayName => realName ?? username;

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'],
      phone: json['phone'],
      realName: json['realName'],
      avatarUrl: json['avatarUrl'],
      userType: json['userType'] ?? 'BUYER',
      status: json['status'],
      companyName: json['companyName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'phone': phone,
    'realName': realName,
    'avatarUrl': avatarUrl,
    'userType': userType,
    'status': status,
    'companyName': companyName,
  };

  /// 序列化为 JSON 字符串（存储用）
  String toJsonString() => jsonEncode(toJson());

  /// 从 JSON 字符串反序列化
  static UserInfo? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return UserInfo.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

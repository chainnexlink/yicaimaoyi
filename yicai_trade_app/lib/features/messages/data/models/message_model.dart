import 'package:easy_localization/easy_localization.dart';

/// 消息数据模型 - 匹配后端 Message entity
class MessageModel {
  final int id;
  final String title;
  final String content;
  final String type;
  final bool isRead;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime? createdAt;

  const MessageModel({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.isRead = false,
    this.actionUrl,
    this.actionLabel,
    this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? json['category'] ?? 'SYSTEM',
      isRead: json['isRead'] ?? json['read'] ?? false,
      actionUrl: json['actionUrl'],
      actionLabel: json['actionLabel'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    'type': type,
    'isRead': isRead,
  };

  /// 消息类型国际化标签
  String get typeLabel => _typeLabelsMap[type] ?? 'messages.system'.tr();

  static Map<String, String> get _typeLabelsMap => {
    'ORDER': 'messages.order'.tr(),
    'SYSTEM': 'messages.system'.tr(),
    'MATCH': 'messages.match_recommend'.tr(),
    'PROMOTION': 'messages.promotion'.tr(),
    'AUCTION': 'messages.auction_notify'.tr(),
    'LOGISTICS': 'messages.logistics_notify'.tr(),
    'CONTRACT': 'messages.contract_notify'.tr(),
  };

  /// Tab索引到API type映射
  static String? tabIndexToType(int index) {
    const map = {1: 'ORDER', 2: 'SYSTEM', 3: 'MATCH', 4: 'PROMOTION'};
    return map[index];
  }
}

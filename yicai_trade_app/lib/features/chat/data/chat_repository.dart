import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/api_constants.dart';

/// 文件附件模型 - 对标网站 chat.html 中的文件消息
class ChatAttachment {
  final String name;
  final String url;
  final String? size;
  final String? mimeType;

  const ChatAttachment({
    required this.name,
    required this.url,
    this.size,
    this.mimeType,
  });

  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      size: json['size'],
      mimeType: json['mimeType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    if (size != null) 'size': size,
    if (mimeType != null) 'mimeType': mimeType,
  };
}

/// 关联订单卡片模型 - 对标网站 chat.html 中的订单卡片消息
class ChatOrderCard {
  final int orderId;
  final String productName;
  final String status;

  const ChatOrderCard({
    required this.orderId,
    required this.productName,
    required this.status,
  });

  factory ChatOrderCard.fromJson(Map<String, dynamic> json) {
    return ChatOrderCard(
      orderId: json['orderId'] ?? 0,
      productName: json['productName'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'orderId': orderId,
    'productName': productName,
    'status': status,
  };
}

/// 聊天消息模型 - 对标网站 chat.html 的消息结构
class ChatMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final String type; // TEXT, IMAGE, FILE, ORDER_CARD, QUOTE, PROGRESS
  final DateTime? createdAt;
  final bool isRead;
  final ChatAttachment? attachment;
  final ChatOrderCard? orderCard;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = 'TEXT',
    this.createdAt,
    this.isRead = false,
    this.attachment,
    this.orderCard,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      receiverId: json['receiverId'] ?? 0,
      senderName: json['senderName'] ?? '',
      senderAvatar: json['senderAvatar'],
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      isRead: json['isRead'] ?? false,
      attachment: json['attachment'] is Map<String, dynamic>
          ? ChatAttachment.fromJson(json['attachment'])
          : null,
      orderCard: json['orderCard'] is Map<String, dynamic>
          ? ChatOrderCard.fromJson(json['orderCard'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'senderName': senderName,
    if (senderAvatar != null) 'senderAvatar': senderAvatar,
    'content': content,
    'type': type,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    'isRead': isRead,
    if (attachment != null) 'attachment': attachment!.toJson(),
    if (orderCard != null) 'orderCard': orderCard!.toJson(),
  };
}

/// 会话模型 - 对标网站 chat.html 中的联系人/会话结构
class Conversation {
  final int id;
  final int targetUserId;
  final String targetName;
  final String? targetAvatar;
  final String? targetCompany;
  final bool isOnline;
  final List<String> badges;
  final String lastMessage;
  final String? lastMessageType;
  final DateTime? lastMessageTime;
  final int unreadCount;

  const Conversation({
    required this.id,
    required this.targetUserId,
    required this.targetName,
    this.targetAvatar,
    this.targetCompany,
    this.isOnline = false,
    this.badges = const [],
    required this.lastMessage,
    this.lastMessageType,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? 0,
      targetUserId: json['targetUserId'] ?? 0,
      targetName: json['targetName'] ?? '',
      targetAvatar: json['targetAvatar'],
      targetCompany: json['targetCompany'],
      isOnline: json['isOnline'] == true,
      badges: json['badges'] is List
          ? (json['badges'] as List).map((e) => e.toString()).toList()
          : const [],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageType: json['lastMessageType'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.tryParse(json['lastMessageTime'].toString())
          : null,
      unreadCount: json['unreadCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetUserId': targetUserId,
    'targetName': targetName,
    if (targetAvatar != null) 'targetAvatar': targetAvatar,
    if (targetCompany != null) 'targetCompany': targetCompany,
    'isOnline': isOnline,
    'badges': badges,
    'lastMessage': lastMessage,
    if (lastMessageType != null) 'lastMessageType': lastMessageType,
    if (lastMessageTime != null)
      'lastMessageTime': lastMessageTime!.toIso8601String(),
    'unreadCount': unreadCount,
  };
}

/// 聊天仓库 - 对接后端 MessageController (/api/admin/messages)
class ChatRepository {
  final Dio _dio;
  ChatRepository(this._dio);

  /// 获取会话列表 (基于消息列表聚合)
  /// 后端无 /conversations 端点，通过获取当前用户消息并按对方用户分组实现
  Future<List<Conversation>> getConversations() async {
    final response = await _dio.get(
      ApiConstants.messages,
      queryParameters: {'page': 0, 'size': 100},
    );
    final data = response.data;
    final body = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    // 后端返回消息列表，客户端聚合为会话
    List rawMessages;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      rawMessages = body['content'] as List;
    } else if (body is List) {
      rawMessages = body;
    } else {
      return [];
    }
    return _aggregateConversations(rawMessages);
  }

  /// 将消息列表聚合为会话列表
  List<Conversation> _aggregateConversations(List rawMessages) {
    final Map<int, Map<String, dynamic>> convMap = {};
    for (final msg in rawMessages) {
      if (msg is! Map<String, dynamic>) continue;
      final senderId = msg['senderId'] as int? ?? 0;
      final receiverId = msg['receiverId'] as int? ?? 0;
      // 对方用户ID（假设当前用户通过上下文判断）
      final targetId = senderId != 0 ? senderId : receiverId;
      if (targetId == 0) continue;

      if (!convMap.containsKey(targetId)) {
        convMap[targetId] = {
          'targetUserId': targetId,
          'targetName': msg['senderName'] ?? '${'chat.user'.tr()}$targetId',
          'targetAvatar': msg['senderAvatar'],
          'lastMessage': msg['content'] ?? '',
          'lastMessageType': msg['type'] ?? 'TEXT',
          'lastMessageTime': msg['createdAt'],
          'unreadCount': (msg['isRead'] == false) ? 1 : 0,
        };
      } else {
        if (msg['isRead'] == false) {
          convMap[targetId]!['unreadCount'] =
              (convMap[targetId]!['unreadCount'] as int) + 1;
        }
      }
    }
    return convMap.values
        .map((e) => Conversation.fromJson({...e, 'id': e['targetUserId']}))
        .toList();
  }

  /// 获取与指定用户的聊天消息 (分页)
  /// 后端端点: GET /api/admin/messages/user/{receiverId}
  Future<List<ChatMessage>> getMessages(
    int targetUserId, {
    int page = 0,
    int size = 20,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.messages}/user/$targetUserId',
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    final body = data is Map<String, dynamic> && data.containsKey('data')
        ? data['data']
        : data;
    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return (body['content'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (body is List) {
      return body
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 发送文本消息: POST /api/admin/messages
  Future<void> sendMessage(
    int receiverId,
    String content, {
    String type = 'TEXT',
  }) async {
    await _dio.post(
      ApiConstants.messages,
      data: {'receiverId': receiverId, 'content': content, 'type': type},
    );
  }

  /// 发送文件消息 - 通过消息体传递文件信息
  /// 后端无独立文件上传端点，将文件信息编码到消息内容中
  Future<void> sendFileMessage(
    int receiverId,
    String filePath,
    String fileName,
  ) async {
    await _dio.post(
      ApiConstants.messages,
      data: {'receiverId': receiverId, 'content': fileName, 'type': 'FILE'},
    );
  }

  /// 标记与目标用户的消息全部已读
  /// 后端端点: POST /api/admin/messages/user/{receiverId}/read-all
  Future<void> markConversationRead(int targetUserId) async {
    await _dio.post('${ApiConstants.messages}/user/$targetUserId/read-all');
  }

  /// 删除单条消息
  /// 后端端点: DELETE /api/admin/messages/{id}
  Future<void> deleteMessage(int messageId) async {
    await _dio.delete('${ApiConstants.messages}/$messageId');
  }

  /// 删除会话 (删除与目标用户的所有消息)
  /// 后端无会话删除端点，通过逐条删除实现
  Future<void> deleteConversation(int conversationId) async {
    // conversationId 在聚合模式下等于 targetUserId
    // 获取该用户所有消息然后删除
    try {
      final messages = await getMessages(conversationId, size: 100);
      for (final msg in messages) {
        await _dio.delete('${ApiConstants.messages}/${msg.id}');
      }
    } catch (_) {}
  }

  /// 获取消息详情: GET /api/admin/messages/{id}
  Future<ChatMessage?> getMessageDetail(int messageId) async {
    try {
      final response = await _dio.get('${ApiConstants.messages}/$messageId');
      final body = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      if (body is Map<String, dynamic>) {
        return ChatMessage.fromJson(body);
      }
    } catch (_) {}
    return null;
  }

  /// 获取未读消息数: GET /api/admin/messages/user/{receiverId}/unread-count
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.messages}/user/$userId/unread-count',
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data['data'] ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

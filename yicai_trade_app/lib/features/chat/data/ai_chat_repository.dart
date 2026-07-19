import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';

class ChatMessage {
  final String role;
  final String content;
  final DateTime? timestamp;

  const ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: json['role'] ?? 'assistant',
    content: json['content'] ?? json['reply'] ?? '',
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// AI 聊天仓库 - 匹配后端 AIChatController
class AiChatRepository {
  final Dio _dio;
  AiChatRepository(this._dio);

  /// 发送消息: POST /api/ai-chat/message
  Future<ChatMessage> sendMessage({
    required String message,
    String? sessionId,
    String? context,
  }) async {
    final r = await _dio.post(
      ApiConstants.aiChatMessage,
      data: {'message': message, 'sessionId': ?sessionId, 'context': ?context},
    );
    final body = r.data is Map<String, dynamic>
        ? (r.data['data'] ?? r.data)
        : r.data;
    if (body is Map<String, dynamic>) {
      return ChatMessage.fromJson(body);
    }
    return ChatMessage(role: 'assistant', content: body.toString());
  }

  /// 健康检查: GET /api/ai-chat/health
  Future<bool> healthCheck() async {
    try {
      await _dio.get(ApiConstants.aiChatHealth);
      return true;
    } catch (_) {
      return false;
    }
  }
}

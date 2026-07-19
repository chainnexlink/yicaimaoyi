import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_response.dart';
import 'models/message_model.dart';

/// 消息仓库 - 匹配后端 MessageController 端点
class MessageRepository {
  final Dio _dio;
  MessageRepository(this._dio);

  /// 查询用户消息: GET /api/admin/messages/user/{receiverId}
  Future<PageResult<MessageModel>> getMessages(
    int userId, {
    String? type,
    int page = 0,
    int size = 10,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};

    String path;
    if (type != null && type.isNotEmpty) {
      // 按类型查询: GET /api/admin/messages/type/{type}
      path = '${ApiConstants.messages}/type/$type';
    } else {
      // 用户全部消息
      path = ApiConstants.messagesByUser(userId);
    }

    final response = await _dio.get(path, queryParameters: params);
    return _parsePageResult(response.data);
  }

  /// 查询用户未读消息: GET /api/admin/messages/user/{receiverId}/unread
  Future<PageResult<MessageModel>> getUnreadMessages(
    int userId, {
    int page = 0,
    int size = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.messagesUnreadByUser(userId),
      queryParameters: {'page': page, 'size': size},
    );
    return _parsePageResult(response.data);
  }

  /// 获取未读数量: GET /api/admin/messages/user/{receiverId}/unread-count
  Future<int> getUnreadCount(int userId) async {
    try {
      final response = await _dio.get(
        ApiConstants.messagesUnreadCount(userId),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['data'] ?? data['count'] ?? 0;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// 标记消息已读: POST /api/admin/messages/{id}/read
  Future<void> markAsRead(int messageId) async {
    await _dio.post('${ApiConstants.messages}/$messageId/read');
  }

  /// 全部标记已读: POST /api/admin/messages/user/{receiverId}/read-all
  Future<void> markAllRead(int userId) async {
    await _dio.post(ApiConstants.messagesReadAll(userId));
  }

  /// 删除消息: DELETE /api/admin/messages/{id}
  Future<void> deleteMessage(int messageId) async {
    await _dio.delete('${ApiConstants.messages}/$messageId');
  }

  /// 获取消息统计: GET /api/admin/messages/stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('${ApiConstants.messages}/stats');
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  PageResult<MessageModel> _parsePageResult(dynamic data) {
    final body =
        data is Map<String, dynamic> && data.containsKey('data')
            ? data['data']
            : data;

    if (body is Map<String, dynamic> && body.containsKey('content')) {
      return PageResult.fromJson(body, (json) => MessageModel.fromJson(json));
    }
    if (body is List) {
      return PageResult(
        content: body
            .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalElements: body.length,
        totalPages: 1,
        pageNumber: 0,
        pageSize: body.length,
      );
    }
    return const PageResult(
      content: [],
      totalElements: 0,
      totalPages: 0,
      pageNumber: 0,
      pageSize: 10,
    );
  }
}

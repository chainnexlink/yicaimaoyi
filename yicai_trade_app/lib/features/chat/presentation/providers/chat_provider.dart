import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';

/// Chat Repository Provider
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.read(dioProvider));
});

/// 会话列表状态
class ConversationListState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;
  final int totalUnread;

  const ConversationListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
    this.totalUnread = 0,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
    int? totalUnread,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalUnread: totalUnread ?? this.totalUnread,
    );
  }
}

/// 会话列表 Provider
final conversationListProvider =
    StateNotifierProvider<ConversationListNotifier, ConversationListState>((
      ref,
    ) {
      return ConversationListNotifier(ref.read(chatRepositoryProvider));
    });

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final ChatRepository _repository;

  ConversationListNotifier(this._repository)
    : super(const ConversationListState());

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repository.getConversations();
      final totalUnread = list.fold<int>(0, (sum, c) => sum + c.unreadCount);
      state = state.copyWith(
        conversations: list,
        isLoading: false,
        totalUnread: totalUnread,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    try {
      await _repository.deleteConversation(conversationId);
      state = state.copyWith(
        conversations: state.conversations
            .where((c) => c.id != conversationId)
            .toList(),
      );
    } catch (_) {}
  }
}

/// 聊天室状态
class ChatRoomState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final String? error;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.error,
  });

  ChatRoomState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    String? error,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

/// 聊天室 Provider - 按目标用户ID创建
final chatRoomProvider = StateNotifierProvider.autoDispose
    .family<ChatRoomNotifier, ChatRoomState, int>((ref, targetUserId) {
      return ChatRoomNotifier(ref.read(chatRepositoryProvider), targetUserId);
    });

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final ChatRepository _repository;
  final int _targetUserId;

  ChatRoomNotifier(this._repository, this._targetUserId)
    : super(const ChatRoomState());

  Future<void> loadMessages({int page = 0}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final msgs = await _repository.getMessages(_targetUserId, page: page);
      state = state.copyWith(
        messages: msgs.reversed.toList(),
        isLoading: false,
      );
      // 标记已读
      _repository.markConversationRead(_targetUserId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> sendMessage(String content, {String type = 'TEXT'}) async {
    if (content.trim().isEmpty || state.isSending) return;
    state = state.copyWith(isSending: true);
    try {
      await _repository.sendMessage(_targetUserId, content, type: type);
      await loadMessages();
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }

  Future<void> sendFileMessage(String filePath, String fileName) async {
    state = state.copyWith(isSending: true);
    try {
      await _repository.sendFileMessage(_targetUserId, filePath, fileName);
      await loadMessages();
    } catch (e) {
      state = state.copyWith(isSending: false, error: e.toString());
    }
  }
}

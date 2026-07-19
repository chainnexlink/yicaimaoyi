import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/message_repository.dart';
import '../../data/models/message_model.dart';

class MessageListState {
  final List<MessageModel> messages;
  final bool isLoading;
  final String? error;
  final int unreadCount;
  final int currentPage;
  final bool hasMore;

  const MessageListState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
    this.currentPage = 0,
    this.hasMore = true,
  });

  MessageListState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    String? error,
    int? unreadCount,
    int? currentPage,
    bool? hasMore,
  }) {
    return MessageListState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final messageRepositoryProvider = Provider<MessageRepository>((ref) {
  return MessageRepository(ref.read(dioProvider));
});

final messageProvider =
    StateNotifierProvider<MessageNotifier, MessageListState>((ref) {
      final userId = ref.watch(currentUserIdProvider);
      return MessageNotifier(ref.read(messageRepositoryProvider), userId: userId);
    });

class MessageNotifier extends StateNotifier<MessageListState> {
  final MessageRepository _repository;
  final int userId;

  MessageNotifier(this._repository, {required this.userId})
      : super(const MessageListState());

  Future<void> loadMessages({String? type}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.getMessages(userId, type: type, page: 0);
      final unread = await _repository.getUnreadCount(userId);
      state = state.copyWith(
        messages: result.content,
        isLoading: false,
        unreadCount: unread,
        currentPage: 0,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      await _repository.markAsRead(messageId);
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id == messageId) {
            return MessageModel(
              id: m.id,
              title: m.title,
              content: m.content,
              type: m.type,
              isRead: true,
              actionUrl: m.actionUrl,
              actionLabel: m.actionLabel,
              createdAt: m.createdAt,
            );
          }
          return m;
        }).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, 999),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _repository.markAllRead(userId);
      state = state.copyWith(
        messages: state.messages
            .map(
              (m) => MessageModel(
                id: m.id,
                title: m.title,
                content: m.content,
                type: m.type,
                isRead: true,
                actionUrl: m.actionUrl,
                actionLabel: m.actionLabel,
                createdAt: m.createdAt,
              ),
            )
            .toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  Future<void> refresh() => loadMessages();
}

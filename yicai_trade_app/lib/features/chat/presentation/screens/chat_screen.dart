import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_repository.dart';
import '../providers/chat_provider.dart';
import 'package:easy_localization/easy_localization.dart';

/// 会话列表页 - 对标网站 chat.html
class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(conversationListProvider.notifier).loadConversations(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationListProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Text('chat.title'.tr(), style: AppTextStyles.headingM),
            if (state.totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.totalUnread > 99 ? '99+' : '${state.totalUnread}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading && state.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.conversations.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(conversationListProvider.notifier)
                  .loadConversations(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.conversations.length,
                separatorBuilder: (_, _) => const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 72,
                  endIndent: 16,
                ),
                itemBuilder: (_, i) =>
                    _ConversationTile(conversation: state.conversations[i]),
              ),
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: AppColors.textPlaceholder.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'chat.no_conversations'.tr(),
            style: AppTextStyles.bodyM.copyWith(
              color: AppColors.textPlaceholder,
            ),
          ),
          const SizedBox(height: 6),
          Text('chat.start_from_supplier'.tr(), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySurface,
            child: conversation.targetAvatar != null
                ? ClipOval(
                    child: Image.network(
                      conversation.targetAvatar!,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (_, _, _) => _avatar(),
                    ),
                  )
                : _avatar(),
          ),
          if (conversation.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        conversation.targetName,
                        style: AppTextStyles.bodyL.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ...conversation.badges
                        .take(2)
                        .map(
                          (badge) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 9,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                if (conversation.targetCompany != null)
                  Text(
                    conversation.targetCompany!,
                    style: AppTextStyles.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (conversation.lastMessageTime != null)
            Text(
              _timeLabel(conversation.lastMessageTime!),
              style: AppTextStyles.caption,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.lastMessageType == 'FILE')
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.attach_file_rounded,
                size: 13,
                color: AppColors.textPlaceholder,
              ),
            ),
          if (conversation.lastMessageType == 'IMAGE')
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.image_outlined,
                size: 13,
                color: AppColors.textPlaceholder,
              ),
            ),
          Expanded(
            child: Text(
              conversation.lastMessage,
              style: AppTextStyles.bodyS,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : '${conversation.unreadCount}',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              targetUserId: conversation.targetUserId,
              targetName: conversation.targetName,
            ),
          ),
        );
      },
    );
  }

  Widget _avatar() {
    return Text(
      conversation.targetName.isNotEmpty ? conversation.targetName[0] : '?',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  String _timeLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'chat.just_now'.tr();
    if (diff.inHours < 1) {
      return 'chat.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inDays < 1) return 'chat.hours_ago'.tr(args: ['${diff.inHours}']);
    if (diff.inDays < 7) return 'chat.days_ago'.tr(args: ['${diff.inDays}']);
    return '${dt.month}/${dt.day}';
  }
}

/// 聊天室页面 - 使用 chatRoomProvider 管理状态
class ChatRoomScreen extends ConsumerStatefulWidget {
  final int targetUserId;
  final String targetName;
  const ChatRoomScreen({
    super.key,
    required this.targetUserId,
    required this.targetName,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(chatRoomProvider(widget.targetUserId).notifier)
          .loadMessages(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatRoomProvider(widget.targetUserId).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentUserIdProvider);
    final state = ref.watch(chatRoomProvider(widget.targetUserId));

    if (!state.isLoading && state.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.cardBg,
        elevation: 0,
        title: Text(widget.targetName, style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                ? Center(
                    child: Text(
                      'chat.no_messages'.tr(),
                      style: AppTextStyles.bodyM.copyWith(
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: state.messages.length,
                    itemBuilder: (_, i) {
                      final msg = state.messages[i];
                      final isMine = msg.senderId == myId;
                      return _MessageBubble(message: msg, isMine: isMine);
                    },
                  ),
          ),
          _buildInputBar(state.isSending),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isSending) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.searchBarBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: _controller,
                style: AppTextStyles.bodyM,
                decoration: InputDecoration(
                  hintText: 'chat.input_message'.tr(),
                  hintStyle: TextStyle(
                    color: AppColors.textPlaceholder,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSending ? AppColors.primaryDark : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0] : '?',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine ? null : Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 文件附件消息
                  if (message.type == 'FILE' && message.attachment != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          size: 18,
                          color: isMine
                              ? AppColors.textOnPrimary
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.attachment!.name,
                                style: AppTextStyles.bodyS.copyWith(
                                  color: isMine
                                      ? AppColors.textOnPrimary
                                      : AppColors.textTitle,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (message.attachment!.size != null)
                                Text(
                                  message.attachment!.size!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMine
                                        ? AppColors.textOnPrimary.withValues(
                                            alpha: 0.7,
                                          )
                                        : AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Text(
                      message.content,
                      style: AppTextStyles.bodyM.copyWith(
                        color: isMine
                            ? AppColors.textOnPrimary
                            : AppColors.textTitle,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    message.createdAt != null
                        ? '${message.createdAt!.hour.toString().padLeft(2, '0')}:${message.createdAt!.minute.toString().padLeft(2, '0')}'
                        : '',
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? AppColors.textOnPrimary.withValues(alpha: 0.6)
                          : AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../data/models/message_model.dart';
import '../providers/message_provider.dart';
import 'package:easy_localization/easy_localization.dart';

/// 消息中心页面 - 真实 API 数据
class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> get _tabs => [
    'messages.all'.tr(),
    'messages.order'.tr(),
    'messages.system'.tr(),
    'messages.match_recommend'.tr(),
    'messages.promotion'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(() => ref.read(messageProvider.notifier).loadMessages());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = MessageModel.tabIndexToType(_tabController.index);
      ref.read(messageProvider.notifier).loadMessages(type: type);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messageProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.3,
        title: Row(
          children: [
            Text('messages.title'.tr(), style: AppTextStyles.headingM),
            const SizedBox(width: 8),
            if (state.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.unreadCount}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: state.unreadCount > 0
                ? () => ref.read(messageProvider.notifier).markAllRead()
                : null,
            child: Text(
              'messages.mark_read'.tr(),
              style: TextStyle(
                color: state.unreadCount > 0
                    ? AppColors.primary
                    : AppColors.textPlaceholder,
                fontSize: 13,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          labelStyle: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTextStyles.bodyM,
          tabAlignment: TabAlignment.start,
          tabs: List.generate(_tabs.length, (i) => Tab(text: _tabs[i])),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (i) => _MessageTabView(tabIndex: i)),
      ),
    );
  }
}

class _MessageTabView extends ConsumerWidget {
  final int tabIndex;
  const _MessageTabView({required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageProvider);

    if (state.isLoading) {
      return const ListCardShimmer();
    }

    if (state.error != null && state.messages.isEmpty) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        onRetry: () => ref.read(messageProvider.notifier).refresh(),
      );
    }

    final messages = state.messages;
    if (messages.isEmpty) {
      return EmptyWidget(
        icon: Icons.mark_email_read_outlined,
        message: 'messages.no_messages'.tr(),
        subtitle: 'messages.no_messages_hint'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(messageProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) => _MessageItem(message: messages[index]),
      ),
    );
  }
}

class _MessageItem extends ConsumerWidget {
  final MessageModel message;
  const _MessageItem({required this.message});

  IconData get _icon {
    switch (message.type) {
      case 'ORDER':
        return Icons.precision_manufacturing_outlined;
      case 'SYSTEM':
        return Icons.info_outline_rounded;
      case 'MATCH':
        return Icons.auto_awesome;
      case 'AUCTION':
        return Icons.gavel_rounded;
      case 'LOGISTICS':
        return Icons.local_shipping_outlined;
      case 'CONTRACT':
        return Icons.draw_outlined;
      case 'PROMOTION':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color get _iconColor {
    switch (message.type) {
      case 'ORDER':
        return AppColors.featureTeal;
      case 'SYSTEM':
        return AppColors.textSecondary;
      case 'MATCH':
        return AppColors.featureYellow;
      case 'AUCTION':
        return AppColors.catPurple;
      case 'LOGISTICS':
        return AppColors.primary;
      case 'CONTRACT':
        return AppColors.warning;
      case 'PROMOTION':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _timeDisplay {
    if (message.createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(message.createdAt!);
    if (diff.inMinutes < 60) {
      return 'chat.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'chat.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    if (diff.inDays < 2) return 'common.yesterday'.tr();
    if (diff.inDays < 7) return 'chat.days_ago'.tr(args: ['${diff.inDays}']);
    return '${message.createdAt!.month}/${message.createdAt!.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        if (!message.isRead) {
          ref.read(messageProvider.notifier).markAsRead(message.id);
        }
        if (message.actionUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${message.actionUrl}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: Container(
        color: !message.isRead
            ? AppColors.primarySurface.withValues(alpha: 0.3)
            : AppColors.cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: _iconColor, size: 22),
                ),
                if (!message.isRead)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message.title,
                          style: AppTextStyles.bodyL.copyWith(
                            color: AppColors.textTitle,
                            fontWeight: !message.isRead
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeDisplay,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.content,
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.actionLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        message.actionLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

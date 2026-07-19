import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

/// 订单管理页面 - V2 主题重新设计
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<String> get _tabs => [
    'order.tab_all'.tr(),
    'order.tab_pending'.tr(),
    'order.tab_confirmed'.tr(),
    'order.tab_production'.tr(),
    'order.tab_shipped'.tr(),
    'order.tab_completed'.tr(),
  ];

  static const _tabApiStatuses = [null, 'PENDING', 'CONFIRMED', 'IN_PRODUCTION', 'SHIPPED', 'COMPLETED'];

  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabApiStatuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(() => ref.read(orderListProvider.notifier).loadOrders());
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final apiStatus = _tabApiStatuses[_tabController.index];
      ref.read(orderListProvider.notifier).loadOrders(status: apiStatus);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    final apiStatus = _tabApiStatuses[_tabController.index];
    ref
        .read(orderListProvider.notifier)
        .loadOrders(
          status: apiStatus,
          keyword: keyword.isEmpty ? null : keyword,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.3,
        title: _showSearch
            ? Container(
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: AppTextStyles.bodyM,
                  decoration: InputDecoration(
                    hintText: 'order.search_hint'.tr(),
                    hintStyle: TextStyle(
                      color: AppColors.textPlaceholder,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(bottom: 10),
                    icon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                  onSubmitted: _onSearch,
                ),
              )
            : Text('orders.title'.tr(), style: AppTextStyles.headingM),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      _onSearch('');
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Icon(
                    _showSearch ? Icons.close_rounded : Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: AppRadius.mdBorder,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.smBorder,
              ),
              labelStyle: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.bodyM,
              tabAlignment: TabAlignment.start,
              dividerColor: Colors.transparent,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: -8,
                vertical: 6,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _OrderTabView(tab: tab)).toList(),
      ),
    );
  }
}

class _OrderTabView extends ConsumerWidget {
  final String tab;
  const _OrderTabView({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderListProvider);

    if (state.isLoading) {
      return const ListCardShimmer();
    }

    if (state.error != null && state.orders.isEmpty) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        onRetry: () => ref.read(orderListProvider.notifier).refresh(),
      );
    }

    final orders = state.orders;
    if (orders.isEmpty) {
      return EmptyWidget(
        icon: Icons.inbox_rounded,
        message: 'order.no_orders'.tr(),
        subtitle: 'order.orders_appear_here'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
      color: AppColors.primary,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification &&
              notification.metrics.extentAfter < 200) {
            ref.read(orderListProvider.notifier).loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length + (state.isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == orders.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return _OrderCard(order: orders[index]);
          },
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.success;
      case 'IN_PRODUCTION':
        return AppColors.featureTeal;
      case 'SHIPPED':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.textSecondary;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: _statusColor.withValues(alpha: 0.1)),
          boxShadow: AppShadows.cardSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.2),
                          AppColors.primary.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.factory_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      order.supplierName,
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTitle,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: _statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      order.statusLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: _statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Divider(height: 0.5, color: AppColors.borderSubtle),
            ),
            // 产品信息
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.cardBgElevated,
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: order.productImage != null
                        ? ClipRRect(
                            borderRadius: AppRadius.mdBorder,
                            child: Image.network(
                              order.productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, e, st) => Icon(
                                Icons.inventory_2_outlined,
                                size: 28,
                                color: AppColors.textPlaceholder,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.inventory_2_outlined,
                            size: 28,
                            color: AppColors.textPlaceholder,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: AppTextStyles.bodyL.copyWith(
                            color: AppColors.textTitle,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${order.quantity}  |  ${'order.order_no_label'.tr()}: ${order.orderNo}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 底部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'order.order_amount'.tr(),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                      Text(
                        '\u00a5${order.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (order.hasTracking)
                        _buildActionBtn(
                          context,
                          'order.track'.tr(),
                          Icons.local_shipping_outlined,
                          AppColors.featureTeal,
                        ),
                      const SizedBox(width: 8),
                      _buildActionBtn(
                        context,
                        'order.detail'.tr(),
                        Icons.chevron_right_rounded,
                        AppColors.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 进度条
            if (order.progress > 0)
              Container(
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  color: AppColors.divider.withValues(alpha: 0.3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: order.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          _statusColor,
                          _statusColor.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (label == 'order.track'.tr() && order.trackingNo != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'order.tracking_no_label'.tr()}: ${order.trackingNo}'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        borderRadius: AppRadius.pillBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            borderRadius: AppRadius.pillBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../providers/admin_provider.dart';

/// 订单审核管理 - 对应网站 admin.html 订单管理模块
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> get _tabs => [
    'admin.all'.tr(),
    'order.status_pending'.tr(),
    'admin.paid'.tr(),
    'order.status_in_production'.tr(),
    'order.status_shipped'.tr(),
    'order.status_completed'.tr(),
    'order.status_cancelled'.tr(),
  ];
  final _statusKeys = [
    null,
    'PENDING',
    'PAID',
    'IN_PRODUCTION',
    'SHIPPED',
    'COMPLETED',
    'CANCELLED',
  ];

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadOrders(_statusKeys[_tabController.index]);
      }
    });
    Future.microtask(() => _loadOrders(null));
  }

  Future<void> _loadOrders(String? status) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final result = await repo.getOrders(status: status);
      if (mounted) {
        setState(() {
          _orders = result.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('admin.orders_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const ListCardShimmer();
    if (_error != null) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        onRetry: () => _loadOrders(_statusKeys[_tabController.index]),
      );
    }
    if (_orders.isEmpty) {
      return EmptyWidget(
        icon: Icons.receipt_long_outlined,
        message: 'admin.no_order_data'.tr(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(_statusKeys[_tabController.index]),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length,
        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] ?? '';
    final statusColor = switch (status) {
      'PENDING' => AppColors.warning,
      'CONFIRMED' || 'PAID' => AppColors.catBlue,
      'IN_PRODUCTION' => AppColors.featureTeal,
      'SHIPPED' => AppColors.primary,
      'COMPLETED' => AppColors.success,
      'CANCELLED' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final statusText = switch (status) {
      'PENDING' => 'order.status_pending'.tr(),
      'CONFIRMED' => 'order.status_confirmed'.tr(),
      'PAID' => 'admin.paid'.tr(),
      'IN_PRODUCTION' => 'order.status_in_production'.tr(),
      'SHIPPED' => 'order.status_shipped'.tr(),
      'RECEIVED' => 'order.status_received'.tr(),
      'COMPLETED' => 'order.status_completed'.tr(),
      'CANCELLED' => 'order.status_cancelled'.tr(),
      _ => status,
    };

    return GestureDetector(
      onTap: () {
        final id = order['id'];
        if (id != null) context.push('/orders/$id');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: AppShadows.cardSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order['orderNo'] ?? order['id'] ?? '-'}',
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textTitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 0.5,
              color: AppColors.divider,
              indent: 16,
              endIndent: 16,
            ),
            // 主体
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: AppColors.textPlaceholder,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order['productName'] ??
                              (order['items'] is List &&
                                      (order['items'] as List).isNotEmpty
                                  ? order['items'][0]['productName'] ??
                                        'common.product'.tr()
                                  : 'common.product'.tr()),
                          style: AppTextStyles.bodyM.copyWith(
                            color: AppColors.textTitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '\u00a5${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                        style: AppTextStyles.price,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _infoChip(
                        Icons.person_outline,
                        '${'order.buyer'.tr()}: ${order['buyerName'] ?? '-'}',
                      ),
                      const SizedBox(width: 12),
                      _infoChip(
                        Icons.factory_outlined,
                        '${'order.supplier'.tr()}: ${order['supplierName'] ?? '-'}',
                      ),
                    ],
                  ),
                  if (order['createdAt'] != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${'common.created'.tr()}: ${order['createdAt']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 操作按钮区
            if (status == 'PENDING' ||
                status == 'PAID' ||
                status == 'IN_PRODUCTION')
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'PENDING') ...[
                      _buildActionBtn(
                        'order.confirm_order'.tr(),
                        Icons.check_circle_outline_rounded,
                        AppColors.success,
                        () => _showOrderAction(
                          order,
                          'CONFIRMED',
                          'order.confirm_order_msg'.tr(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildActionBtn(
                        'order.cancel_order'.tr(),
                        Icons.cancel_outlined,
                        AppColors.error,
                        () => _showOrderAction(
                          order,
                          'CANCELLED',
                          'order.cancel_order_msg'.tr(),
                        ),
                      ),
                    ],
                    if (status == 'PAID')
                      _buildActionBtn(
                        'order.mark_production'.tr(),
                        Icons.precision_manufacturing_outlined,
                        AppColors.featureTeal,
                        () => _showOrderAction(
                          order,
                          'IN_PRODUCTION',
                          'order.mark_production_msg'.tr(),
                        ),
                      ),
                    if (status == 'IN_PRODUCTION')
                      _buildActionBtn(
                        'order.mark_shipped'.tr(),
                        Icons.local_shipping_outlined,
                        AppColors.primary,
                        () => _showOrderAction(
                          order,
                          'SHIPPED',
                          'order.mark_shipped_msg'.tr(),
                        ),
                      ),
                    const SizedBox(width: 10),
                    _buildActionBtn(
                      'admin.add_remark'.tr(),
                      Icons.note_add_outlined,
                      AppColors.catBlue,
                      () => _showRemarkDialog(order),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textPlaceholder),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppRadius.pillBorder,
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
    );
  }

  void _showOrderAction(
    Map<String, dynamic> order,
    String newStatus,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('admin.order_action'.tr(), style: AppTextStyles.headingS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${'order.order_no'.tr()}: ${order['orderNo'] ?? order['id'] ?? '-'}',
              style: TextStyle(fontSize: 12, color: AppColors.textPlaceholder),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _updateOrderStatus(order, newStatus);
            },
            child: Text(
              'common.confirm'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showRemarkDialog(Map<String, dynamic> order) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('admin.add_remark'.tr(), style: AppTextStyles.headingS),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: AppTextStyles.bodyM,
          decoration: InputDecoration(
            hintText: 'admin.remark_hint'.tr(),
            hintStyle: TextStyle(color: AppColors.textPlaceholder),
            filled: true,
            fillColor: AppColors.searchBarBg,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdBorder,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                _showSnack('admin.remark_saved'.tr());
              }
            },
            child: Text(
              'common.save'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(
    Map<String, dynamic> order,
    String newStatus,
  ) async {
    try {
      setState(() {
        order['status'] = newStatus;
      });
      _showSnack('common.action_success'.tr());
    } catch (e) {
      _showSnack('${'common.action_failed'.tr()}: $e');
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.cardBgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      );
    }
  }
}

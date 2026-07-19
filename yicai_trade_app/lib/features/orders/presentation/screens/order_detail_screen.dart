import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/router/route_names.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order_model.dart';
import '../providers/order_provider.dart';

/// 订单详情页 - 对标网站 order-detail.html，完整订单监控闭环
class OrderDetailScreen extends ConsumerStatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  OrderModel? _order;
  bool _loading = true;
  String? _error;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(orderRepositoryProvider);
      final order = await repo.getOrderDetail(widget.orderId);
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String get _userType {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) return authState.user.userType;
    return 'BUYER';
  }

  int get _userId {
    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) return authState.user.id;
    return 0;
  }

  bool get _isBuyer => _userType != 'SUPPLIER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('orders.order_detail'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_order != null)
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              color: AppColors.cardBg,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
              onSelected: (v) => _onMenuAction(v),
              itemBuilder: (_) => [
                _popupItem('chat', Icons.chat_outlined, 'order.contact_other'.tr()),
                if (_order!.status == 'COMPLETED')
                  _popupItem('review', Icons.star_outline_rounded, 'order.review_order'.tr()),
                _popupItem('copy', Icons.copy_rounded, 'order.copy_order_no'.tr()),
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  PopupMenuItem<String> _popupItem(String value, IconData icon, String text) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(text, style: AppTextStyles.bodyM),
        ],
      ),
    );
  }

  void _onMenuAction(String action) {
    switch (action) {
      case 'chat':
        context.push(RouteNames.chat);
        break;
      case 'review':
        _showSnack('order.review_coming_soon'.tr());
        break;
      case 'copy':
        if (_order != null) {
          Clipboard.setData(ClipboardData(text: _order!.orderNo));
          _showSnack('order.order_no_copied'.tr());
        }
        break;
    }
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _order == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'common.load_failed'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadOrder,
              child: Text(
                'common.retry'.tr(),
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }

    final order = _order!;
    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(order),
            const SizedBox(height: 12),
            _buildProgressTimeline(order),
            const SizedBox(height: 12),
            // 监控入口卡片 - 订单处于生产/发货/已收货状态时显示
            if (_shouldShowMonitorEntry(order)) ...[
              _buildMonitorEntryCard(order),
              const SizedBox(height: 12),
            ],
            _buildProductInfo(order),
            const SizedBox(height: 12),
            _buildOrderInfo(order),
            const SizedBox(height: 12),
            if (order.hasTracking) ...[
              _buildLogisticsCard(order),
              const SizedBox(height: 12),
            ],
            _buildActionButtons(order),
            const SizedBox(height: 12),
            _buildQuickActions(order),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  bool _shouldShowMonitorEntry(OrderModel order) {
    const monitorStates = [
      'PAID',
      'IN_PRODUCTION',
      'PRODUCTION',
      'SHIPPED',
      'RECEIVED',
      'COMPLETED',
    ];
    return monitorStates.contains(order.status);
  }

  Widget _buildStatusCard(OrderModel order) {
    final color = _statusColor(order.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), AppColors.cardBg],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '\u00a5${order.amount.toStringAsFixed(2)}',
                style: AppTextStyles.priceL,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(order.orderNo, style: AppTextStyles.bodyS)),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: order.orderNo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('order.order_no_copied'.tr()),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (order.createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              '${'orders.create_time'.tr()}: ${_formatDate(order.createdAt!)}',
              style: AppTextStyles.caption,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(OrderModel order) {
    final steps = [
      _TimelineStep('order.step_placed'.tr(), Icons.shopping_cart_outlined, 0.0),
      _TimelineStep('orders.confirmed'.tr(), Icons.check_circle_outline, 0.2),
      _TimelineStep('orders.production'.tr(), Icons.factory_outlined, 0.5),
      _TimelineStep('orders.shipped'.tr(), Icons.local_shipping_outlined, 0.8),
      _TimelineStep('orders.completed'.tr(), Icons.verified_outlined, 1.0),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('orders.order_progress'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 16),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIdx = index ~/ 2;
                final active = order.progress >= steps[stepIdx + 1].threshold;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: active ? AppColors.primary : AppColors.divider,
                  ),
                );
              }
              final step = steps[index ~/ 2];
              final active = order.progress >= step.threshold;
              final current =
                  order.progress >= step.threshold &&
                  (index ~/ 2 == steps.length - 1 ||
                      order.progress < steps[index ~/ 2 + 1].threshold);
              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: current
                          ? AppColors.primary
                          : active
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.pageBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.divider,
                        width: current ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      step.icon,
                      size: 18,
                      color: current
                          ? AppColors.textOnPrimary
                          : active
                          ? AppColors.primary
                          : AppColors.textPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: active
                          ? AppColors.textTitle
                          : AppColors.textPlaceholder,
                      fontWeight: current ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('orders.product_detail'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.pageBg,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: order.productImage != null
                    ? ClipRRect(
                        borderRadius: AppRadius.mdBorder,
                        child: Image.network(
                          order.productImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _productPlaceholder(),
                        ),
                      )
                    : _productPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.productName,
                      style: AppTextStyles.bodyL.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTitle,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _infoRow('orders.quantity'.tr(), order.quantity),
                    _infoRow('order.unit_price'.tr(), '\u00a5${order.amount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('orders.order_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _detailRow('orders.order_no'.tr(), order.orderNo),
          _detailRow('order.supplier'.tr(), order.supplierName),
          _detailRow('orders.order_status'.tr(), order.statusLabel),
          _detailRow(
            'orders.order_amount'.tr(),
            '\u00a5${order.amount.toStringAsFixed(2)}',
            valueColor: AppColors.textPrice,
          ),
          if (order.createdAt != null)
            _detailRow(
              'orders.create_time'.tr(),
              _formatDate(order.createdAt!),
            ),
          if (order.updatedAt != null)
            _detailRow('order.update_time'.tr(), _formatDate(order.updatedAt!)),
          if (order.remark != null && order.remark!.isNotEmpty)
            _detailRow('orders.remark'.tr(), order.remark!),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 20,
                color: AppColors.featureTeal,
              ),
              const SizedBox(width: 8),
              Text('order.logistics_info'.tr(), style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: 12),
          _detailRow('logistics.tracking_no'.tr(), order.trackingNo ?? '-'),
          _detailRow(
            'order.order_status'.tr(),
            order.status == 'SHIPPED'
                ? 'logistics.status_transit'.tr()
                : 'logistics.status_delivered'.tr(),
          ),
        ],
      ),
    );
  }

  /// 生产监控入口卡片 - 订单与监控的核心联动
  Widget _buildMonitorEntryCard(OrderModel order) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.productionMonitor),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.featureTeal.withValues(alpha: 0.15),
              AppColors.cardBg,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.lgBorder,
          border: Border.all(
            color: AppColors.featureTeal.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.monitorTopBar,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.monitor_heart_outlined,
                size: 22,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'production.title'.tr(),
                    style: AppTextStyles.bodyL.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.featureTeal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isBuyer
                        ? 'production.view_progress'.tr()
                        : 'production.upload_progress'.tr(),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (!_isBuyer)
              GestureDetector(
                onTap: () => context.push(RouteNames.monitorUpload),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.featureTeal,
                    borderRadius: AppRadius.pillBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 14,
                        color: AppColors.textOnPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'production.upload'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, color: AppColors.featureTeal),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    final actions = <Widget>[];

    if (_isBuyer) {
      switch (order.status) {
        case 'PENDING':
          actions.add(
            _actionButton(
              'orders.cancel_order'.tr(),
              AppColors.error,
              Icons.close_rounded,
              () => _confirmAction(
                'order.confirm_cancel'.tr(),
                'order.cancel_irreversible'.tr(),
                () => _performAction('cancel', order),
              ),
              outlined: true,
            ),
          );
          actions.add(const SizedBox(width: 10));
          actions.add(
            _actionButton(
              'order.go_pay'.tr(),
              AppColors.primary,
              Icons.payment_rounded,
              () => _performAction('pay', order),
            ),
          );
          break;
        case 'CONFIRMED':
          actions.add(
            _actionButton(
              'order.go_pay'.tr(),
              AppColors.primary,
              Icons.payment_rounded,
              () => _performAction('pay', order),
            ),
          );
          break;
        case 'SHIPPED':
          actions.add(
            _actionButton(
              'order.confirm_receipt'.tr(),
              AppColors.primary,
              Icons.check_rounded,
              () => _confirmAction(
                'order.confirm_receipt_title'.tr(),
                'order.release_escrow'.tr(),
                () => _performAction('receipt', order),
              ),
            ),
          );
          break;
        case 'RECEIVED':
          actions.add(
            _actionButton(
              'order.complete_order'.tr(),
              AppColors.success,
              Icons.verified_rounded,
              () => _performAction('complete', order),
            ),
          );
          break;
      }
    } else {
      switch (order.status) {
        case 'PENDING':
          actions.add(
            _actionButton(
              'order.reject_order'.tr(),
              AppColors.error,
              Icons.close_rounded,
              () => _confirmAction(
                'order.confirm_reject'.tr(),
                'order.reject_irreversible'.tr(),
                () => _performAction('reject', order),
              ),
              outlined: true,
            ),
          );
          actions.add(const SizedBox(width: 10));
          actions.add(
            _actionButton(
              'order.accept_order'.tr(),
              AppColors.primary,
              Icons.check_circle_outline,
              () => _showConfirmOrderDialog(order),
            ),
          );
          break;
        case 'CONFIRMED':
        case 'PAID':
        case 'IN_PRODUCTION':
        case 'PRODUCTION':
          actions.add(
            _actionButton(
              'production.upload_progress'.tr(),
              AppColors.featureTeal,
              Icons.cloud_upload_outlined,
              () => context.push(RouteNames.monitorUpload),
              outlined: true,
            ),
          );
          actions.add(const SizedBox(width: 10));
          actions.add(
            _actionButton(
              'orders.mark_shipped'.tr(),
              AppColors.primary,
              Icons.local_shipping_outlined,
              () => _showShipOrderDialog(order),
            ),
          );
          break;
      }
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions.map((a) {
        if (a is SizedBox) return a;
        return Expanded(child: a);
      }).toList(),
    );
  }

  /// 快捷操作行
  Widget _buildQuickActions(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickAction(
            Icons.chat_bubble_outline_rounded,
            'order.contact_other'.tr(),
            AppColors.catBlue,
            () => context.push(RouteNames.chat),
          ),
          if (_shouldShowMonitorEntry(order))
            _quickAction(
              Icons.monitor_heart_outlined,
              'production.title'.tr(),
              AppColors.featureTeal,
              () => context.push(RouteNames.productionMonitor),
            ),
          _quickAction(
            Icons.description_outlined,
            'order.contract'.tr(),
            AppColors.catPurple,
            () => context.push(RouteNames.contractList),
          ),
          if (order.status == 'COMPLETED')
            _quickAction(
              Icons.star_outline_rounded,
              'order.review'.tr(),
              AppColors.featureYellow,
              () => _showSnack('order.review_coming_soon'.tr()),
            )
          else
            _quickAction(
              Icons.help_outline_rounded,
              'order.help'.tr(),
              AppColors.textSecondary,
              () => context.push(RouteNames.helpCenter),
            ),
        ],
      ),
    );
  }

  Widget _quickAction(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap, {
    bool outlined = false,
  }) {
    return GestureDetector(
      onTap: _actionInProgress ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color,
          borderRadius: AppRadius.lgBorder,
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_actionInProgress)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: outlined ? color : Colors.white,
                ),
              )
            else ...[
              Icon(icon, size: 20, color: outlined ? color : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.button.copyWith(
                  color: outlined ? color : Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 确认弹窗
  void _confirmAction(String title, String subtitle, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(title, style: AppTextStyles.headingS),
        content: Text(
          subtitle,
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
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
              onConfirm();
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

  /// 供应商确认订单弹窗
  void _showConfirmOrderDialog(OrderModel order) {
    DateTime? selectedDate;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
          title: Text(
            'orders.confirm_order'.tr(),
            style: AppTextStyles.headingS,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'order.select_delivery_date'.tr(),
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: AppColors.primary,
                          surface: AppColors.cardBg,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.searchBarBg,
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: selectedDate != null
                            ? AppColors.primary
                            : AppColors.textPlaceholder,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'order.tap_select_date'.tr(),
                        style: TextStyle(
                          color: selectedDate != null
                              ? AppColors.textTitle
                              : AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
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
              onPressed: selectedDate == null
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      _performAction(
                        'confirm',
                        order,
                        extra: {
                          'estimatedDeliveryDate':
                              '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                        },
                      );
                    },
              child: Text(
                'orders.confirm_order'.tr(),
                style: TextStyle(
                  color: selectedDate != null
                      ? AppColors.primary
                      : AppColors.textPlaceholder,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 供应商发货弹窗
  void _showShipOrderDialog(OrderModel order) {
    final trackingCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text('orders.mark_shipped'.tr(), style: AppTextStyles.headingS),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
              decoration: InputDecoration(
                hintText: 'logistics.carrier'.tr(),
                hintStyle: TextStyle(color: AppColors.textPlaceholder),
                filled: true,
                fillColor: AppColors.searchBarBg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.textPlaceholder,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: trackingCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
              decoration: InputDecoration(
                hintText: 'logistics.tracking_no'.tr(),
                hintStyle: TextStyle(color: AppColors.textPlaceholder),
                filled: true,
                fillColor: AppColors.searchBarBg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdBorder,
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.qr_code_rounded,
                  color: AppColors.textPlaceholder,
                  size: 20,
                ),
              ),
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
              if (trackingCtrl.text.isEmpty || companyCtrl.text.isEmpty) {
                ScaffoldMessenger.of(
                  ctx,
                ).showSnackBar(SnackBar(content: Text('order.fill_logistics_info'.tr())));
                return;
              }
              Navigator.pop(ctx);
              _performAction(
                'ship',
                order,
                extra: {
                  'trackingNumber': trackingCtrl.text,
                  'logisticsCompany': companyCtrl.text,
                },
              );
            },
            child: Text(
              'orders.mark_shipped'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(
    String action,
    OrderModel order, {
    Map<String, dynamic>? extra,
  }) async {
    setState(() => _actionInProgress = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      switch (action) {
        case 'cancel':
        case 'reject':
          await repo.cancelOrder(order.id, operatorId: _userId);
          break;
        case 'pay':
          await repo.payOrder(order.id, buyerId: _userId);
          break;
        case 'confirm':
          await repo.confirmOrder(
            order.id,
            supplierId: _userId,
            estimatedDeliveryDate: extra?['estimatedDeliveryDate'],
          );
          break;
        case 'ship':
          await repo.shipOrder(
            order.id,
            supplierId: _userId,
            trackingNumber: extra?['trackingNumber'] ?? '',
            logisticsCompany: extra?['logisticsCompany'] ?? '',
          );
          break;
        case 'receipt':
          await repo.confirmReceipt(order.id, buyerId: _userId);
          break;
        case 'complete':
          await repo.completeOrder(order.id, operatorId: _userId);
          break;
      }
      await _loadOrder();
      ref.read(orderListProvider.notifier).refresh();
      _showSnack('common.action_success'.tr());
    } catch (e) {
      _showSnack('${'common.operation_failed'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  Widget _productPlaceholder() => Icon(
    Icons.inventory_2_outlined,
    size: 32,
    color: AppColors.textPlaceholder,
  );

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Text('$label: ', style: AppTextStyles.caption),
          Text(
            value,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textTitle),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.caption)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(
                color: valueColor ?? AppColors.textTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.success;
      case 'IN_PRODUCTION':
        return AppColors.featureTeal;
      case 'SHIPPED':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final double threshold;
  const _TimelineStep(this.label, this.icon, this.threshold);
}

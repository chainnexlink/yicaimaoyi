import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/empty_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/supplier_center_provider.dart';

/// 供应商订单管理 - 对应网站 supplier-order-list.html，实现完整操作闭环
class SupplierOrdersScreen extends ConsumerStatefulWidget {
  const SupplierOrdersScreen({super.key});

  @override
  ConsumerState<SupplierOrdersScreen> createState() =>
      _SupplierOrdersScreenState();
}

class _SupplierOrdersScreenState extends ConsumerState<SupplierOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = [
    'supplier_center.orders_all',
    'supplier_center.orders_pending',
    'supplier_center.orders_production',
    'supplier_center.orders_shipping',
    'supplier_center.orders_completed',
  ];
  final _statusKeys = [null, 'PENDING', 'PRODUCING', 'SHIPPING', 'COMPLETED'];

  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _actionInProgress = false;

  int get _userId {
    final authState = ref.read(authProvider);
    return authState is AuthAuthenticated ? authState.user.id : 0;
  }

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
      final repo = ref.read(supplierCenterRepositoryProvider);
      final result = await repo.getOrders(_userId, status: status);
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
        backgroundColor: AppColors.cardBg,
        title: Text(
          'supplier_center.orders_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t.tr())).toList(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ListCardShimmer();
    }
    if (_error != null) {
      return ErrorStateWidget(
        message: 'common.load_failed'.tr(),
        subtitle: _error,
        onRetry: () => _loadOrders(_statusKeys[_tabController.index]),
      );
    }
    if (_orders.isEmpty) {
      return EmptyWidget(
        icon: Icons.receipt_long_outlined,
        message: 'supplier_center.orders_all'.tr(),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.cardBg,
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
      'PRODUCING' => AppColors.catBlue,
      'SHIPPING' => AppColors.featureTeal,
      'COMPLETED' => AppColors.success,
      'CANCELLED' => AppColors.error,
      _ => AppColors.textSecondary,
    };
    final statusText = switch (status) {
      'PENDING' => 'supplier_center.orders_pending'.tr(),
      'PRODUCING' => 'supplier_center.orders_production'.tr(),
      'SHIPPING' => 'supplier_center.orders_shipping'.tr(),
      'COMPLETED' => 'supplier_center.orders_completed'.tr(),
      'CANCELLED' => status,
      _ => status,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部 - 订单号 + 状态
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${'supplier_center.order_no'.tr()}: ${order['orderNo'] ?? order['id'] ?? '-'}',
                    style: AppTextStyles.bodyS.copyWith(
                      color: AppColors.textSecondary,
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
          const Divider(
            height: 0.5,
            color: AppColors.divider,
            indent: 16,
            endIndent: 16,
          ),
          // 主体 - 产品信息
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.searchBarBg,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.textPlaceholder,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['productName'] ?? 'supplier_center.product'.tr(),
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.textTitle,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${'supplier_center.quantity'.tr()}: ${order['quantity'] ?? '-'}  |  ${'supplier_center.buyer'.tr()}: ${order['buyerName'] ?? '-'}',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '\u00a5${(order['totalAmount'] ?? 0).toStringAsFixed(2)}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
          ),
          // 底部操作
          if (status == 'PENDING' ||
              status == 'SHIPPING' ||
              status == 'PRODUCING') ...[
            const Divider(
              height: 0.5,
              color: AppColors.divider,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'PENDING') ...[
                    TextButton(
                      onPressed: _actionInProgress
                          ? null
                          : () => _rejectOrder(order),
                      child: Text(
                        'supplier_center.reject'.tr(),
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _actionInProgress
                          ? null
                          : () => _acceptOrder(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'supplier_center.accept_order'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  if (status == 'PRODUCING') ...[
                    OutlinedButton.icon(
                      onPressed: () => context.push(RouteNames.monitorUpload),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: Text(
                        'supplier_center.upload_progress'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.featureTeal,
                        side: const BorderSide(color: AppColors.featureTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _actionInProgress
                          ? null
                          : () => _showShipDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'supplier_center.confirm_ship'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                  if (status == 'SHIPPING')
                    ElevatedButton(
                      onPressed: _actionInProgress
                          ? null
                          : () => _showShipDialog(order),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.featureTeal,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'supplier_center.confirm_ship'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============ 订单操作方法 ============

  Future<void> _acceptOrder(Map<String, dynamic> order) async {
    final orderId = order['id'] as int;
    final date = await showDatePicker(
      context: context,
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
    if (date == null) return;
    setState(() => _actionInProgress = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      await repo.confirmOrder(
        orderId,
        supplierId: _userId,
        estimatedDeliveryDate: dateStr,
      );
      _showSnack('supplier_center.order_accepted'.tr());
      await _loadOrders(_statusKeys[_tabController.index]);
    } catch (e) {
      _showSnack('${'common.operation_failed'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _rejectOrder(Map<String, dynamic> order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          'supplier_center.confirm_reject'.tr(),
          style: AppTextStyles.headingS,
        ),
        content: Text(
          'supplier_center.reject_note'.tr(),
          style: AppTextStyles.bodyM.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'supplier_center.reject'.tr(),
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _actionInProgress = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      await repo.cancelOrder(order['id'] as int, operatorId: _userId);
      _showSnack('supplier_center.order_rejected'.tr());
      await _loadOrders(_statusKeys[_tabController.index]);
    } catch (e) {
      _showSnack('${'common.operation_failed'.tr()}: $e');
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _showShipDialog(Map<String, dynamic> order) {
    final trackingCtrl = TextEditingController();
    final companyCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
        title: Text(
          'supplier_center.confirm_ship'.tr(),
          style: AppTextStyles.headingS,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: companyCtrl,
              style: AppTextStyles.bodyM.copyWith(color: AppColors.textTitle),
              decoration: InputDecoration(
                hintText: 'supplier_center.carrier_label'.tr(),
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
                hintText: 'supplier_center.tracking_no_label'.tr(),
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
            onPressed: () async {
              if (trackingCtrl.text.isEmpty || companyCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('supplier_center.fill_logistics'.tr()),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              setState(() => _actionInProgress = true);
              try {
                final repo = ref.read(orderRepositoryProvider);
                await repo.shipOrder(
                  order['id'] as int,
                  supplierId: _userId,
                  trackingNumber: trackingCtrl.text,
                  logisticsCompany: companyCtrl.text,
                );
                _showSnack('supplier_center.ship_success'.tr());
                await _loadOrders(_statusKeys[_tabController.index]);
              } catch (e) {
                _showSnack('${'common.operation_failed'.tr()}: $e');
              } finally {
                if (mounted) setState(() => _actionInProgress = false);
              }
            },
            child: Text(
              'supplier_center.confirm_ship'.tr(),
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }
}

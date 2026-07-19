import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/order_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// 交付确认流程 - 对应网站 delivery-confirm.html
class DeliveryConfirmScreen extends ConsumerStatefulWidget {
  const DeliveryConfirmScreen({super.key});

  @override
  ConsumerState<DeliveryConfirmScreen> createState() =>
      _DeliveryConfirmScreenState();
}

class _DeliveryConfirmScreenState extends ConsumerState<DeliveryConfirmScreen> {
  List<OrderModel> _deliveries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(orderRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      final userType = ref.read(currentUserTypeProvider);
      // 加载已发货和已收货的订单
      final result = userType == 'SUPPLIER'
          ? await repo.getOrdersBySupplier(userId, status: 'SHIPPED')
          : await repo.getOrdersByBuyer(userId, status: 'SHIPPED');
      final received = userType == 'SUPPLIER'
          ? await repo.getOrdersBySupplier(userId, status: 'RECEIVED')
          : await repo.getOrdersByBuyer(userId, status: 'RECEIVED');
      final completed = userType == 'SUPPLIER'
          ? await repo.getOrdersBySupplier(userId, status: 'COMPLETED')
          : await repo.getOrdersByBuyer(
              userId,
              status: 'COMPLETED',
              page: 0,
              size: 5,
            );
      setState(() {
        _deliveries = [
          ...result.content,
          ...received.content,
          ...completed.content,
        ];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'supplier_center.delivery_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 64,
                    color: AppColors.textPlaceholder.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'supplier_center.no_delivery'.tr(),
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _deliveries.length,
                itemBuilder: (context, index) =>
                    _buildDeliveryCard(_deliveries[index]),
              ),
            ),
    );
  }

  Widget _buildDeliveryCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productName,
                        style: AppTextStyles.bodyL.copyWith(
                          color: AppColors.textTitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${'supplier_center.order_no'.tr()}: ${order.orderNo}  |  ${'supplier_center.quantity'.tr()}: ${order.quantity}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(order.status),
              ],
            ),
          ),
          const Divider(
            height: 0.5,
            color: AppColors.divider,
            indent: 16,
            endIndent: 16,
          ),

          // 交付进度
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTimeline(order),
          ),

          // 操作按钮
          if (order.status == 'SHIPPED' || order.status == 'RECEIVED') ...[
            const Divider(
              height: 0.5,
              color: AppColors.divider,
              indent: 16,
              endIndent: 16,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'SHIPPED')
                    ElevatedButton.icon(
                      onPressed: () => _confirmDelivery(order),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: Text(
                        'supplier_center.confirm_receive'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.featureTeal,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  if (order.status == 'RECEIVED') ...[
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'supplier_center.issue_feedback'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _acceptDelivery(order),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(
                        'supplier_center.check_passed'.tr(),
                        style: TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.textOnPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (color, text) = switch (status) {
      'SHIPPED' => (AppColors.catBlue, 'supplier_center.status_transit'.tr()),
      'RECEIVED' => (
        AppColors.warning,
        'supplier_center.status_pending_check'.tr(),
      ),
      'COMPLETED' => (AppColors.success, 'supplier_center.status_checked'.tr()),
      _ => (AppColors.textSecondary, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final isShipped = [
      'SHIPPED',
      'RECEIVED',
      'COMPLETED',
    ].contains(order.status);
    final isReceived = ['RECEIVED', 'COMPLETED'].contains(order.status);
    final isCompleted = order.status == 'COMPLETED';

    final steps = <_TimelineStep>[
      _TimelineStep(
        'supplier_center.ship_label'.tr(),
        isShipped,
        isShipped ? _formatDate(order.updatedAt ?? order.createdAt) : null,
      ),
      _TimelineStep(
        'supplier_center.sign_label'.tr(),
        isReceived,
        isReceived ? _formatDate(order.updatedAt) : null,
      ),
      _TimelineStep(
        'supplier_center.check_label'.tr(),
        isCompleted,
        isCompleted ? _formatDate(order.updatedAt) : null,
      ),
    ];

    return Row(
      children: steps.asMap().entries.map((entry) {
        final i = entry.key;
        final step = entry.value;
        return Expanded(
          child: Row(
            children: [
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    color: step.completed
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                ),
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step.completed
                          ? AppColors.primary
                          : AppColors.searchBarBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.completed ? Icons.check : Icons.circle_outlined,
                      size: 14,
                      color: step.completed
                          ? AppColors.textOnPrimary
                          : AppColors.textPlaceholder,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.label,
                    style: TextStyle(
                      fontSize: 11,
                      color: step.completed
                          ? AppColors.primary
                          : AppColors.textPlaceholder,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (step.date != null)
                    Text(
                      step.date!,
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.textPlaceholder,
                      ),
                    ),
                ],
              ),
              if (i < steps.length - 1) const SizedBox(),
            ],
          ),
        );
      }).toList(),
    );
  }

  String? _formatDate(DateTime? dt) {
    if (dt == null) return null;
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelivery(OrderModel order) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.confirmReceipt(order.id, buyerId: userId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('supplier_center.received'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'common.operation_failed'.tr()}: $e')));
      }
    }
  }

  Future<void> _acceptDelivery(OrderModel order) async {
    try {
      final repo = ref.read(orderRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      await repo.completeOrder(order.id, operatorId: userId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('supplier_center.check_passed'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'common.operation_failed'.tr()}: $e')));
      }
    }
  }
}

class _TimelineStep {
  final String label;
  final bool completed;
  final String? date;
  _TimelineStep(this.label, this.completed, this.date);
}

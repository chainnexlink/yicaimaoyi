import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../orders/data/models/order_model.dart';
import '../../../orders/presentation/providers/order_provider.dart';

/// 根据 orderId 获取订单详情
final _orderDetailProvider = FutureProvider.family.autoDispose<OrderModel, int>(
  (ref, id) {
    return ref.read(orderRepositoryProvider).getOrderDetail(id);
  },
);

/// 供应商订单详情页 - 对标网站 supplier-order-detail.html
/// 供应商视角的订单详情，含生产监控上传入口
class SupplierOrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const SupplierOrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncOrder = ref.watch(_orderDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'supplier_center.order_detail_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('supplier_center.print_coming_soon'.tr()),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('supplier_center.share_coming_soon'.tr()),
                ),
              );
            },
          ),
        ],
      ),
      body: asyncOrder.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('common.load_failed'.tr(), style: AppTextStyles.bodyM),
              const SizedBox(height: 4),
              Text(
                err.toString(),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_orderDetailProvider(orderId)),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (order) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildTimeline(order),
              const SizedBox(height: 16),
              _buildBuyerInfoCard(context, order),
              const SizedBox(height: 12),
              _buildProductDetailsCard(order),
              const SizedBox(height: 12),
              _buildMonitoringSection(context, order),
              const SizedBox(height: 12),
              _buildOrderInfoCard(order),
              const SizedBox(height: 12),
              _buildActionButtons(context, order),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(OrderModel order) {
    final stages = [
      'order.status_pending_confirm'.tr(),
      'order.status_confirmed'.tr(),
      'order.status_in_production'.tr(),
      'order.status_shipped'.tr(),
      'order.status_completed'.tr(),
    ];
    final statusIndex = _statusToIndex(order.status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'supplier_center.order_progress'.tr(),
                style: AppTextStyles.headingS,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withValues(alpha: 0.1),
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  order.statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(stages.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stageIdx = i ~/ 2;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: stageIdx < statusIndex
                        ? AppColors.primary
                        : AppColors.divider,
                  ),
                );
              }
              final stageIdx = i ~/ 2;
              final isCompleted = stageIdx < statusIndex;
              final isCurrent = stageIdx == statusIndex;
              return Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.primary
                          : isCurrent
                              ? AppColors.primarySurface
                              : AppColors.pageBg,
                      border: Border.all(
                        color: isCurrent || isCompleted
                            ? AppColors.primary
                            : AppColors.divider,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : isCurrent
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[stageIdx],
                    style: TextStyle(
                      fontSize: 10,
                      color: isCompleted || isCurrent
                          ? AppColors.primary
                          : AppColors.textPlaceholder,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
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

  Widget _buildBuyerInfoCard(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier_center.buyer_info'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  'B',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${'supplier_center.buyer_label'.tr()} #${order.buyerId ?? ''}',
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${'supplier_center.order_no_label'.tr()}: ${order.orderNo}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: () => context.push(RouteNames.messages),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier_center.product_detail'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          _productItem(
            order.productName.isNotEmpty
                ? order.productName
                : 'supplier_center.default_product'.tr(),
            order.quantity.isNotEmpty ? order.quantity : '-',
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'supplier_center.order_total'.tr(),
                style: AppTextStyles.headingS,
              ),
              Text(
                '\u00a5${order.amount.toStringAsFixed(2)}',
                style: AppTextStyles.priceL,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _productItem(String name, String qty) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.pageBg,
            borderRadius: AppRadius.mdBorder,
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            color: AppColors.textPlaceholder,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${'supplier_center.quantity_label'.tr()}: $qty',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringSection(BuildContext context, OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'supplier_center.production_monitor'.tr(),
                style: AppTextStyles.headingS,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.status == 'IN_PRODUCTION'
                      ? AppColors.warningBg
                      : AppColors.successBg,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  order.status == 'IN_PRODUCTION' ? 'order.status_in_production'.tr() : order.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: order.status == 'IN_PRODUCTION'
                        ? AppColors.warning
                        : AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 进度条
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'supplier_center.production_progress'.tr(),
                style: AppTextStyles.bodyM,
              ),
              Text(
                '${(order.progress * 100).toInt()}%',
                style: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: LinearProgressIndicator(
              value: order.progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.pageBg,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(RouteNames.monitorUpload),
              icon: const Icon(Icons.cloud_upload_outlined, size: 18),
              label: Text('supplier_center.upload_monitor_data'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.featureTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdBorder,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfoCard(OrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'supplier_center.order_info'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          _infoRow('supplier_center.order_no_label'.tr(), order.orderNo),
          _infoRow('order.order_amount'.tr(), '\u00a5${order.amount.toStringAsFixed(2)}'),
          _infoRow('order.order_status'.tr(), order.statusLabel),
          if (order.createdAt != null)
            _infoRow('common.created'.tr(), _formatDate(order.createdAt!)),
          if (order.trackingNo != null && order.trackingNo!.isNotEmpty)
            _infoRow('order.tracking_no_label'.tr(), order.trackingNo!),
          if (order.remark != null && order.remark!.isNotEmpty)
            _infoRow('order.remark'.tr(), order.remark!),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppTextStyles.bodyS)),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyM.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, OrderModel order) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(RouteNames.monitorUpload),
            icon: const Icon(Icons.cloud_upload_outlined, size: 18),
            label: Text('supplier_center.upload_monitor_data'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.mdBorder,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'supplier_center.print_coming_soon'.tr(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.print_outlined, size: 16),
                label: Text('supplier_center.print'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'supplier_center.export_coming_soon'.tr(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.download_outlined, size: 16),
                label: Text('supplier_center.export'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _statusToIndex(String status) {
    switch (status) {
      case 'PENDING':
        return 0;
      case 'CONFIRMED':
        return 1;
      case 'IN_PRODUCTION':
        return 2;
      case 'SHIPPED':
        return 3;
      case 'COMPLETED':
      case 'RECEIVED':
        return 4;
      default:
        return 0;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'IN_PRODUCTION':
        return AppColors.featureTeal;
      case 'SHIPPED':
        return AppColors.primary;
      case 'COMPLETED':
      case 'RECEIVED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      default:
        return AppColors.featureYellow;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

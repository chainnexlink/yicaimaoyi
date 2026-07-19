import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/logistics_repository.dart';
import '../providers/logistics_provider.dart';

/// 物流追踪详情 Provider
final _trackingDetailProvider = FutureProvider.family
    .autoDispose<_TrackingDetail, int>((ref, orderId) async {
      final repo = ref.read(logisticsRepositoryProvider);
      // 先通过 orderId 获取物流信息
      final list = await repo.list(page: 0, size: 1);
      final info = list.content.isNotEmpty ? list.content.first : null;
      TrackingQueryResult? tracking;
      if (info?.trackingNo != null && info!.trackingNo!.isNotEmpty) {
        try {
          tracking = await repo.queryTracking(info.trackingNo!);
        } catch (_) {}
      }
      return _TrackingDetail(info: info, tracking: tracking);
    });

class _TrackingDetail {
  final LogisticsInfo? info;
  final TrackingQueryResult? tracking;
  const _TrackingDetail({this.info, this.tracking});
}

/// 物流追踪页 - 对接后端真实数据
class LogisticsTrackingScreen extends ConsumerWidget {
  final int orderId;
  const LogisticsTrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncValue = ref.watch(_trackingDetailProvider(orderId));

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('logistics.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(height: 12),
              Text('common.load_failed'.tr(), style: AppTextStyles.bodyM),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(_trackingDetailProvider(orderId)),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (detail) => _buildContent(context, detail),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _TrackingDetail detail) {
    final info = detail.info;
    final tracking = detail.tracking;
    final events = tracking?.events ?? [];

    if (info == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping_outlined,
              size: 64,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'logistics.no_tracking'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusCard(info),
          const SizedBox(height: 16),
          _buildShipmentInfoCard(context, info),
          const SizedBox(height: 16),
          if (events.isNotEmpty) ...[
            _buildTimelineCard(events),
            const SizedBox(height: 16),
          ],
          _buildActionCard(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatusCard(LogisticsInfo info) {
    final statusLabel = _statusLabel(info.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.9),
          ),
          const SizedBox(height: 12),
          Text(
            statusLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (info.updatedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              '${'order.updated_at'.tr()} ${_formatDate(info.updatedAt!)}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShipmentInfoCard(BuildContext context, LogisticsInfo info) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('logistics.track_detail'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          _infoRow('logistics.carrier'.tr(), info.carrier ?? 'common.unknown'.tr()),
          _infoRow('logistics.tracking_no'.tr(), info.trackingNo ?? 'common.none'.tr()),
          if (info.createdAt != null)
            _infoRow('order.ship_time'.tr(), _formatDate(info.createdAt!)),
          _infoRow('order.related_order'.tr(), 'ORD-$orderId'),
          if (info.trackingNo != null && info.trackingNo!.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: info.trackingNo!));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('order.tracking_no_copied'.tr())));
                },
                icon: const Icon(Icons.content_copy_outlined, size: 14),
                label: Text('order.copy_tracking_no'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdBorder,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: AppTextStyles.bodyS)),
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

  Widget _buildTimelineCard(List<TrackingEvent> events) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('order.logistics_track'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 16),
          ...events.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isFirst = i == 0;
            final isLast = i == events.length - 1;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFirst
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: AppColors.divider,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.description,
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: isFirst
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isFirst
                                  ? AppColors.textTitle
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(e.time, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('order.confirm_receipt_hint'.tr())));
        },
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: Text('order.confirm_receipt'.tr()),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'SHIPPED':
        return 'order.status_shipped'.tr();
      case 'IN_TRANSIT':
        return 'logistics.status_transit'.tr();
      case 'DELIVERED':
        return 'logistics.status_signed'.tr();
      case 'PENDING':
        return 'order.status_pending_ship'.tr();
      case 'RETURNED':
        return 'order.status_returned'.tr();
      default:
        return status;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

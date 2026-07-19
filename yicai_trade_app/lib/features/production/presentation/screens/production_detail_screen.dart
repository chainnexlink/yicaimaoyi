import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/monitor_model.dart';
import '../providers/monitor_provider.dart';

/// 根据 monitorId 获取生产监控详情
final _monitorDetailProvider = FutureProvider.family
    .autoDispose<MonitorModel, int>((ref, id) {
      return ref.read(monitorRepositoryProvider).getMonitorDetail(id);
    });

/// 生产详情页 - 对标网站 production-detail.html
/// 展示生产任务的阶段进度、更新记录、证据上传
class ProductionDetailScreen extends ConsumerStatefulWidget {
  final int monitorId;
  const ProductionDetailScreen({super.key, required this.monitorId});

  @override
  ConsumerState<ProductionDetailScreen> createState() =>
      _ProductionDetailScreenState();
}

class _ProductionDetailScreenState
    extends ConsumerState<ProductionDetailScreen> {
  int _expandedStage = -1; // 当前展开的阶段, -1=无

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(_monitorDetailProvider(widget.monitorId));

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'production.detail_title'.tr(),
          style: AppTextStyles.headingM,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('orders.export_coming'.tr())),
              );
            },
          ),
        ],
      ),
      body: asyncDetail.when(
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
                onPressed: () =>
                    ref.invalidate(_monitorDetailProvider(widget.monitorId)),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
        data: (monitor) {
          // 找到当前进行中的阶段，默认展开
          if (_expandedStage == -1 && monitor.timeline.isNotEmpty) {
            for (int i = 0; i < monitor.timeline.length; i++) {
              if (monitor.timeline[i].status == 'IN_PROGRESS' ||
                  (!monitor.timeline[i].completed &&
                      (i == 0 || monitor.timeline[i - 1].completed))) {
                _expandedStage = i;
                break;
              }
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildOverviewCard(monitor),
                const SizedBox(height: 16),
                _buildProgressCard(monitor),
                const SizedBox(height: 16),
                ...monitor.timeline.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _buildStageCard(e.key, e.value, monitor),
                  ),
                ),
                if (monitor.timeline.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: AppRadius.lgBorder,
                    ),
                    child: Center(
                      child: Text(
                        'production.no_production'.tr(),
                        style: AppTextStyles.caption,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                _buildSupplierCard(monitor),
                const SizedBox(height: 12),
                _buildRelatedOrderCard(monitor),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(MonitorModel monitor) {
    final statusColor = _statusColor(monitor.status);
    final daysLeft = monitor.expectedDelivery
        ?.difference(DateTime.now())
        .inDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'production.task_label'.tr()} #PM-${widget.monitorId}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  monitor.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            monitor.productName.isNotEmpty
                ? '${monitor.productName}${monitor.quantity != null ? ' - ${monitor.quantity}${'common.unit_piece'.tr()}' : ''}'
                : '${'production.task_title'.tr()} #${widget.monitorId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${'production.related_order'.tr()}: ${monitor.orderNo.isNotEmpty ? monitor.orderNo : 'production.not_linked'.tr()}',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.white60),
              const SizedBox(width: 4),
              Text(
                monitor.expectedDelivery != null
                    ? '${'production.expected_completion'.tr()}: ${_formatDate(monitor.expectedDelivery!)}'
                    : '${'production.expected_completion'.tr()}: ${'production.to_be_determined'.tr()}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              if (daysLeft != null) ...[
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.white60,
                ),
                const SizedBox(width: 4),
                Text(
                  daysLeft > 0
                      ? 'production.days_remaining'.tr(args: ['$daysLeft'])
                      : (daysLeft == 0 ? 'production.due_today'.tr() : 'production.overdue_days'.tr(args: ['${-daysLeft}'])),
                  style: TextStyle(
                    color: daysLeft < 0 ? Colors.redAccent : Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(MonitorModel monitor) {
    final total = monitor.timeline.length;
    final completed = monitor.timeline.where((t) => t.completed).length;
    final inProgress = monitor.timeline
        .where((t) => t.status == 'IN_PROGRESS')
        .length;
    final pending = total - completed - inProgress;
    final progressValue = total > 0 ? monitor.progress / 100 : 0.0;

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
            'production.overall_progress'.tr(),
            style: AppTextStyles.headingS,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('production.completion_rate'.tr(), style: AppTextStyles.bodyS),
                        Text(
                          '${monitor.progress.toInt()}%',
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
                        value: progressValue.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppColors.pageBg,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _progressStat(
                'production.completed'.tr(),
                total > 0 ? '$completed/$total' : '0',
                AppColors.success,
              ),
              const SizedBox(width: 12),
              _progressStat('production.in_progress'.tr(), '$inProgress', AppColors.primary),
              const SizedBox(width: 12),
              _progressStat('production.pending_start'.tr(), '$pending', AppColors.textPlaceholder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdBorder,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard(int index, TimelineNode node, MonitorModel monitor) {
    final isExpanded = _expandedStage == index;
    final isCompleted = node.completed;
    final isCurrent =
        node.status == 'IN_PROGRESS' ||
        (!node.completed &&
            (index == 0 || monitor.timeline[index - 1].completed));

    Color statusColor = AppColors.textPlaceholder;
    String statusLabel = 'production.pending_start'.tr();
    if (isCompleted) {
      statusColor = AppColors.success;
      statusLabel = 'production.completed'.tr();
    } else if (isCurrent) {
      statusColor = AppColors.primary;
      statusLabel = 'production.in_progress'.tr();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: isCurrent
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _expandedStage = isExpanded ? -1 : index),
            borderRadius: AppRadius.lgBorder,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? AppColors.success
                          : (isCurrent ? AppColors.primary : AppColors.pageBg),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isCurrent
                                    ? Colors.white
                                    : AppColors.textPlaceholder,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          node.label,
                          style: AppTextStyles.bodyM.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (node.time.isNotEmpty)
                          Text(node.time, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: AppRadius.pillBorder,
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.textPlaceholder,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _detailItem('production.stage_status'.tr(), statusLabel),
                      _detailItem(
                        'production.time'.tr(),
                        node.time.isNotEmpty ? node.time : 'production.to_be_determined'.tr(),
                      ),
                      _detailItem('production.total_progress'.tr(), '${monitor.progress.toInt()}%'),
                    ],
                  ),
                  if (isCurrent) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('production.confirm_on_web'.tr())),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                              ),
                            ),
                            child: Text('common.confirm'.tr()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showReportIssueDialog(monitor),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.mdBorder,
                              ),
                            ),
                            child: Text(
                              'production.report_issue'.tr(),
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ),
                      ],
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

  void _showReportIssueDialog(MonitorModel monitor) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('production.report_quality_issue'.tr()),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'production.describe_issue_hint'.tr(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final desc = controller.text.trim();
              if (desc.isEmpty) return;
              Navigator.of(ctx).pop();
              try {
                await ref.read(monitorRepositoryProvider).markQualityIssue(
                  monitor.id,
                  {'description': desc, 'orderId': monitor.orderId},
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('production.issue_reported'.tr())),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('production.report_failed'.tr())));
                }
              }
            },
            child: Text('common.submit'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.bodyS.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierCard(MonitorModel monitor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('production.supplier_info'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySurface,
                child: Text(
                  monitor.supplierName.isNotEmpty
                      ? monitor.supplierName[0]
                      : 'S',
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
                      monitor.supplierName.isNotEmpty
                          ? monitor.supplierName
                          : 'production.supplier'.tr(),
                      style: AppTextStyles.bodyM.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${'production.related_order'.tr()}: ${monitor.orderNo}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push(RouteNames.messages),
                icon: const Icon(Icons.chat_outlined, size: 14),
                label: Text('production.contact'.tr()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pillBorder,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedOrderCard(MonitorModel monitor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('production.related_order'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 12),
          InkWell(
            onTap: monitor.orderId > 0
                ? () => context.push('/orders/${monitor.orderId}')
                : null,
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 20,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monitor.orderNo.isNotEmpty ? monitor.orderNo : 'production.no_linked_order'.tr(),
                        style: AppTextStyles.bodyM.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${monitor.productName}${monitor.quantity != null ? ' x ${monitor.quantity}${'common.unit_piece'.tr()}' : ''}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textPlaceholder,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(RouteNames.contractList),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                  ),
                  child: Text('production.view_contract'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('orders.export_coming'.tr())),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                  ),
                  child: Text('orders.export'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push(RouteNames.messages),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdBorder,
                    ),
                  ),
                  child: Text('production.chat_history'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'PRODUCING':
        return AppColors.featureTeal;
      case 'QC':
        return AppColors.featureYellow;
      case 'SHIPPING':
        return AppColors.primary;
      case 'COMPLETED':
        return AppColors.success;
      case 'DELAYED':
        return AppColors.error;
      default:
        return AppColors.featureTeal;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

/// 平台数据统计页面 - 管理后台数据分析
class AdminStatisticsScreen extends ConsumerStatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  ConsumerState<AdminStatisticsScreen> createState() =>
      _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends ConsumerState<AdminStatisticsScreen> {
  String _period = 'month';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminDashboardProvider.notifier).loadData(period: _period),
    );
  }

  void _changePeriod(String period) {
    setState(() => _period = period);
    ref.read(adminDashboardProvider.notifier).loadData(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(adminDashboardProvider);
    final data = dashState.data;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('admin.stats_title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _changePeriod,
            icon: Icon(
              Icons.date_range_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
            color: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: AppRadius.lgBorder),
            itemBuilder: (ctx) => [
              _periodItem('week', 'admin.this_week'.tr()),
              _periodItem('month', 'admin.this_month'.tr()),
              _periodItem('quarter', 'admin.this_quarter'.tr()),
              _periodItem('year', 'admin.this_year'.tr()),
            ],
          ),
        ],
      ),
      body: dashState.isLoading && data.totalOrders == 0
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(adminDashboardProvider.notifier)
                  .loadData(period: _period),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPeriodChips(),
                  const SizedBox(height: 16),
                  _buildTradeSummary(data),
                  const SizedBox(height: 16),
                  _buildOrderTrendChart(data),
                  const SizedBox(height: 16),
                  _buildUserOverview(data),
                  const SizedBox(height: 16),
                  _buildRecentOrders(data),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  PopupMenuItem<String> _periodItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_period == value)
            Icon(Icons.check_rounded, size: 16, color: AppColors.primary)
          else
            const SizedBox(width: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _period == value ? AppColors.primary : AppColors.textBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChips() {
    final periods = [
      ('week', 'admin.this_week'.tr()),
      ('month', 'admin.this_month'.tr()),
      ('quarter', 'admin.this_quarter'.tr()),
      ('year', 'admin.this_year'.tr()),
    ];
    return Row(
      children: periods.map((p) {
        final selected = _period == p.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _changePeriod(p.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.cardBgElevated,
                borderRadius: AppRadius.pillBorder,
                border: Border.all(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTradeSummary(AdminDashboardData data) {
    final completionRate = data.totalOrders > 0
        ? (data.completedOrders / data.totalOrders * 100)
        : 0.0;
    final avgAmount = data.totalOrders > 0
        ? data.totalRevenue / data.totalOrders
        : 0.0;

    final items = [
      _SummaryItem(
        'admin.trade_total'.tr(),
        '¥${_formatAmount(data.totalRevenue)}',
        Icons.monetization_on_outlined,
        AppColors.success,
      ),
      _SummaryItem(
        'admin.order_count'.tr(),
        '${data.totalOrders}',
        Icons.receipt_long_outlined,
        AppColors.catBlue,
      ),
      _SummaryItem(
        'admin.avg_order'.tr(),
        '¥${avgAmount.toStringAsFixed(0)}',
        Icons.trending_up_rounded,
        AppColors.secondary,
      ),
      _SummaryItem(
        'admin.completion_rate'.tr(),
        '${completionRate.toStringAsFixed(1)}%',
        Icons.check_circle_outline_rounded,
        AppColors.primary,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: item.color.withValues(alpha: 0.12)),
            boxShadow: AppShadows.cardSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: 16, color: item.color),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderTrendChart(AdminDashboardData data) {
    final trend = data.orderTrend;
    if (trend.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: AppRadius.lgBorder,
          boxShadow: AppShadows.cardSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text('admin.order_trend'.tr(), style: AppTextStyles.headingS),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'admin.no_trend_data'.tr(),
                style: AppTextStyles.bodyM.copyWith(
                  color: AppColors.textPlaceholder,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final maxVal = trend.fold<int>(0, (p, e) => e.count > p ? e.count : p);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('admin.order_trend'.tr(), style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend.map((item) {
                final h = maxVal > 0
                    ? (item.count / maxVal * 110).clamp(4.0, 110.0)
                    : 4.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${item.count}',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          height: h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textPlaceholder,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserOverview(AdminDashboardData data) {
    final items = [
      (
        'admin.total_users'.tr(),
        data.totalUsers,
        AppColors.primary,
        Icons.people_outline_rounded,
      ),
      (
        'admin.buyers'.tr(),
        data.totalBuyers,
        AppColors.catBlue,
        Icons.shopping_cart_outlined,
      ),
      (
        'admin.suppliers_count'.tr(),
        data.totalSuppliers,
        AppColors.featureTeal,
        Icons.factory_outlined,
      ),
      (
        'admin.pending_process'.tr(),
        data.pendingOrders,
        AppColors.warning,
        Icons.pending_actions_outlined,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text('admin.user_overview'.tr(), style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.$4, size: 20, color: item.$3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.$2}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: item.$3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(AdminDashboardData data) {
    final orders = data.recentOrders;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text('admin.recent_orders'.tr(), style: AppTextStyles.headingS),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'admin.no_order_data'.tr(),
                  style: AppTextStyles.bodyM.copyWith(
                    color: AppColors.textPlaceholder,
                  ),
                ),
              ),
            )
          else
            ...orders.map((order) {
              final statusColor = switch (order.status) {
                'COMPLETED' => AppColors.success,
                'CANCELLED' => AppColors.error,
                'PENDING' => AppColors.warning,
                _ => AppColors.catBlue,
              };
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.orderNo,
                              style: AppTextStyles.bodyS.copyWith(
                                color: AppColors.textTitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.buyerName} -> ${order.supplierName}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '¥${_formatAmount(order.amount)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrice,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(1)}${'common.ten_thousand'.tr()}';
    }
    return amount.toStringAsFixed(0);
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryItem(this.label, this.value, this.icon, this.color);
}

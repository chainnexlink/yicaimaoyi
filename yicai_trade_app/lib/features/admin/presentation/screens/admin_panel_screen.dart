import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/router/route_names.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_provider.dart';

/// 后台管理主页 - 对应网站 admin.html
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(adminDashboardProvider.notifier).loadData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('admin.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'common.load_failed'.tr(),
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.read(adminDashboardProvider.notifier).refresh(),
                    child: Text(
                      'common.retry'.tr(),
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(adminDashboardProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildOverviewCards(state.data),
                  const SizedBox(height: 16),
                  _buildQuickNav(),
                  const SizedBox(height: 16),
                  _buildRevenueCard(state.data),
                  const SizedBox(height: 16),
                  _buildRecentOrders(state.data),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildOverviewCards(AdminDashboardData data) {
    final items = [
      _StatItem(
        'admin.total_users'.tr(),
        '${data.totalUsers}',
        Icons.people_rounded,
        AppColors.primary,
      ),
      _StatItem(
        'admin.buyers'.tr(),
        '${data.totalBuyers}',
        Icons.shopping_bag_outlined,
        AppColors.catBlue,
      ),
      _StatItem(
        'admin.suppliers_count'.tr(),
        '${data.totalSuppliers}',
        Icons.factory_outlined,
        AppColors.featureTeal,
      ),
      _StatItem(
        'admin.total_orders'.tr(),
        '${data.totalOrders}',
        Icons.receipt_long_outlined,
        AppColors.secondary,
      ),
      _StatItem(
        'admin.pending_process'.tr(),
        '${data.pendingOrders}',
        Icons.pending_actions_rounded,
        AppColors.warning,
      ),
      _StatItem(
        'admin.active_monitors'.tr(),
        '${data.activeMonitors}',
        Icons.monitor_heart_outlined,
        AppColors.catPurple,
      ),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.15,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: item.color.withValues(alpha: 0.15)),
            boxShadow: AppShadows.cardSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, size: 16, color: item.color),
              ),
              Text(
                item.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickNav() {
    final navItems = [
      _NavItem(
        'admin.user_manage'.tr(),
        Icons.people_outline_rounded,
        AppColors.catBlue,
        RouteNames.adminUsers,
      ),
      _NavItem(
        'admin.order_review'.tr(),
        Icons.fact_check_outlined,
        AppColors.secondary,
        RouteNames.adminOrders,
      ),
      _NavItem(
        'admin.statistics'.tr(),
        Icons.bar_chart_rounded,
        AppColors.catPurple,
        RouteNames.adminStatistics,
      ),
      _NavItem(
        'admin.content_manage'.tr(),
        Icons.article_outlined,
        AppColors.catOrange,
        RouteNames.adminContent,
      ),
      _NavItem(
        'admin.monitor_center'.tr(),
        Icons.monitor_heart_outlined,
        AppColors.featureTeal,
        RouteNames.productionMonitor,
      ),
      _NavItem(
        'admin.system_settings'.tr(),
        Icons.settings_outlined,
        AppColors.textSecondary,
        RouteNames.adminSettings,
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
          Text('admin.quick_actions'.tr(), style: AppTextStyles.headingS),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: navItems.map((item) {
              return GestureDetector(
                onTap: () => context.push(item.route),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, size: 24, color: item.color),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _buildRevenueCard(AdminDashboardData data) {
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 16,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'admin.revenue_overview'.tr(),
                style: AppTextStyles.headingS,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.monthly_revenue'.tr(),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u00a5${_formatAmount(data.monthRevenue)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.divider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin.total_revenue'.tr(),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\u00a5${_formatAmount(data.totalRevenue)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.orderTrend.isNotEmpty) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.orderTrend.map((point) {
                  final max = data.orderTrend.fold<int>(
                    1,
                    (p, e) => e.count > p ? e.count : p,
                  );
                  final h = max > 0
                      ? (point.count / max * 80).clamp(4.0, 80.0)
                      : 4.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${point.count}',
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            point.label,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppColors.textPlaceholder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentOrders(AdminDashboardData data) {
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Text('admin.recent_orders'.tr(), style: AppTextStyles.headingS),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push(RouteNames.adminOrders),
                child: Text(
                  'common.view_all'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (data.recentOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'admin.no_order_data'.tr(),
                  style: TextStyle(color: AppColors.textPlaceholder),
                ),
              ),
            )
          else
            ...data.recentOrders.take(5).map((order) => _buildOrderRow(order)),
        ],
      ),
    );
  }

  Widget _buildOrderRow(AdminRecentOrder order) {
    final statusColor = switch (order.status) {
      'PENDING' => AppColors.warning,
      'CONFIRMED' || 'PAID' => AppColors.catBlue,
      'IN_PRODUCTION' => AppColors.featureTeal,
      'SHIPPED' => AppColors.primary,
      'COMPLETED' => AppColors.success,
      'CANCELLED' => AppColors.error,
      _ => AppColors.textSecondary,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => context.push('/orders/${order.id}'),
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
                      style: AppTextStyles.caption,
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
                    '\u00a5${order.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrice,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem(this.label, this.value, this.icon, this.color);
}

class _NavItem {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _NavItem(this.label, this.icon, this.color, this.route);
}

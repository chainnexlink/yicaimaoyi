import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/supplier_center_provider.dart';
import '../../data/models/supplier_product_model.dart';

/// 供应商中心工作台 - V2 主题重新设计
class SupplierCenterScreen extends ConsumerStatefulWidget {
  const SupplierCenterScreen({super.key});

  @override
  ConsumerState<SupplierCenterScreen> createState() =>
      _SupplierCenterScreenState();
}

class _SupplierCenterScreenState extends ConsumerState<SupplierCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(supplierDashboardProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(supplierDashboardProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cardBg,
        onRefresh: () =>
            ref.read(supplierDashboardProvider.notifier).loadStats(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _buildHeader(topPadding),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildStatsGrid(dashState.stats),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildRevenueCard(dashState.stats),
            ),
            _buildSectionTitle('supplier_center.quick_actions'.tr()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQuickActions(),
            ),
            _buildSectionTitle('supplier_center.management'.tr()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildManageMenu(),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.bodyS.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textTitle,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'supplier_center.title'.tr(),
                    style: AppTextStyles.headingM.copyWith(
                      color: AppColors.textTitle,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'common.certified'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withValues(alpha: 0.25),
                          AppColors.featureTeal.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.store_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'supplier_center.my_store'.tr(),
                          style: AppTextStyles.headingS.copyWith(
                            color: AppColors.textTitle,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'supplier_center.my_store_desc'.tr(),
                          style: AppTextStyles.bodyS.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(SupplierDashboardStats? stats) {
    final items = [
      _StatItem(
        '${stats?.totalProducts ?? 0}',
        'supplier_center.total_products'.tr(),
        Icons.inventory_2_outlined,
        AppColors.primary,
      ),
      _StatItem(
        '${stats?.pendingOrders ?? 0}',
        'supplier_center.pending_orders'.tr(),
        Icons.pending_actions_outlined,
        AppColors.warning,
      ),
      _StatItem(
        '${stats?.completedOrders ?? 0}',
        'supplier_center.completed_orders'.tr(),
        Icons.check_circle_outline,
        AppColors.success,
      ),
      _StatItem(
        '${stats?.totalInquiries ?? 0}',
        'supplier_center.inquiries'.tr(),
        Icons.mail_outline_rounded,
        AppColors.catBlue,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withValues(alpha: 0.2),
                        item.color.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.color.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueCard(SupplierDashboardStats? stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2137), Color(0xFF0A3D2E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        boxShadow: AppShadows.cardMedium,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'supplier_center.monthly_revenue'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u00a5${stats?.monthlyRevenue.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSubtle),
          Expanded(
            child: Column(
              children: [
                Text(
                  'supplier_center.total_revenue'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\u00a5${stats?.totalRevenue.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTitle,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.borderSubtle),
          Expanded(
            child: Column(
              children: [
                Text(
                  'supplier_center.score'.tr(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.featureYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      stats?.averageRating.toStringAsFixed(1) ?? '0.0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.featureYellow,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        Icons.add_box_outlined,
        'supplier_center.add_product'.tr(),
        AppColors.primary,
        () => context.push(RouteNames.supplierProductEdit),
      ),
      _QuickAction(
        Icons.inventory_outlined,
        'supplier_center.product_manage'.tr(),
        AppColors.catPurple,
        () => context.push(RouteNames.supplierProducts),
      ),
      _QuickAction(
        Icons.receipt_long_outlined,
        'supplier_center.order_manage'.tr(),
        AppColors.featureYellow,
        () => context.push(RouteNames.supplierOrders),
      ),
      _QuickAction(
        Icons.upload_file_outlined,
        'supplier_center.progress_upload'.tr(),
        AppColors.featureTeal,
        () => context.push(RouteNames.monitorUpload),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: actions.map((action) {
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: AppRadius.mdBorder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.color.withValues(alpha: 0.2),
                              action.color.withValues(alpha: 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: action.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Icon(action.icon, color: action.color, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.label,
                        style: AppTextStyles.bodyS.copyWith(
                          color: AppColors.textTitle,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManageMenu() {
    final items = [
      _MenuItem(
        Icons.storefront_outlined,
        'supplier_center.store_settings'.tr(),
        'supplier_center.store_settings_desc'.tr(),
        AppColors.primary,
        () {},
      ),
      _MenuItem(
        Icons.local_shipping_outlined,
        'supplier_center.delivery_manage'.tr(),
        'supplier_center.delivery_manage_desc'.tr(),
        AppColors.featureTeal,
        () => context.push(RouteNames.deliveryConfirm),
      ),
      _MenuItem(
        Icons.monitor_heart_outlined,
        'supplier_center.monitor_settings'.tr(),
        'supplier_center.monitor_settings_desc'.tr(),
        AppColors.catBlue,
        () => context.push(RouteNames.monitorSettings),
      ),
      _MenuItem(
        Icons.description_outlined,
        'supplier_center.contract_manage'.tr(),
        'supplier_center.contract_manage_desc'.tr(),
        AppColors.catPurple,
        () => context.push(RouteNames.contractList),
      ),
      _MenuItem(
        Icons.analytics_outlined,
        'supplier_center.data_analysis'.tr(),
        'supplier_center.data_analysis_desc'.tr(),
        AppColors.featureYellow,
        () => context.push(RouteNames.dashboard),
      ),
      _MenuItem(
        Icons.chat_bubble_outline_rounded,
        'supplier_center.customer_chat'.tr(),
        'supplier_center.customer_chat_desc'.tr(),
        AppColors.success,
        () => context.push(RouteNames.chat),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: AppShadows.cardSmall,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: i == 0
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        )
                      : i == items.length - 1
                      ? const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        )
                      : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                item.color.withValues(alpha: 0.2),
                                item.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: item.color.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: AppTextStyles.bodyL.copyWith(
                                  color: AppColors.textTitle,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.subtitle,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.textPlaceholder,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textPlaceholder,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (i < items.length - 1)
                Divider(
                  height: 0.5,
                  indent: 70,
                  endIndent: 16,
                  color: AppColors.borderSubtle,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _StatItem {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  _StatItem(this.value, this.label, this.icon, this.color);
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  _QuickAction(this.icon, this.label, this.color, this.onTap);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.icon, this.label, this.subtitle, this.color, this.onTap);
}

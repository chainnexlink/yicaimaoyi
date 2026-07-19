import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

/// 数据看板页面 - V2 主题重新设计
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _selectedPeriod = '';

  @override
  void initState() {
    super.initState();
    _selectedPeriod = 'dashboard.this_month'.tr();
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadData());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('dashboard.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final periods = [
                    'dashboard.this_month'.tr(),
                    'dashboard.this_quarter'.tr(),
                    'dashboard.this_year'.tr(),
                  ];
                  final idx =
                      (periods.indexOf(_selectedPeriod) + 1) % periods.length;
                  setState(() => _selectedPeriod = periods[idx]);
                  final apiPeriod = ['month', 'quarter', 'year'][idx];
                  ref
                      .read(dashboardProvider.notifier)
                      .loadData(period: apiPeriod);
                },
                borderRadius: AppRadius.pillBorder,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: AppRadius.pillBorder,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedPeriod,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.data.kpis.isEmpty
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
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () =>
                          ref.read(dashboardProvider.notifier).refresh(),
                      borderRadius: AppRadius.pillBorder,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: AppRadius.pillBorder,
                        ),
                        child: Text(
                          'common.retry'.tr(),
                          style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(dashboardProvider.notifier).refresh(),
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildKpiGrid(state.data),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    'dashboard.order_trend'.tr(),
                    Icons.trending_up_rounded,
                    AppColors.primary,
                    _buildOrderTrendChart(state.data),
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    'dashboard.category_dist'.tr(),
                    Icons.pie_chart_outline_rounded,
                    AppColors.catPurple,
                    _buildCategoryPieChart(state.data),
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    'dashboard.supplier_rank'.tr(),
                    Icons.emoji_events_outlined,
                    AppColors.featureYellow,
                    _buildSupplierRanking(state.data),
                  ),
                  const SizedBox(height: 12),
                  _buildChartCard(
                    'dashboard.cost_analysis'.tr(),
                    Icons.donut_large_rounded,
                    AppColors.secondary,
                    _buildCostBreakdown(state.data),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiGrid(DashboardData data) {
    final kpis = data.kpis;
    final defaultKpis = kpis.isEmpty
        ? [
            KpiItem(
              label: 'dashboard.total_orders'.tr(),
              value: '--',
              change: '--',
            ),
            KpiItem(
              label: 'dashboard.total_purchase'.tr(),
              value: '--',
              change: '--',
            ),
            KpiItem(
              label: 'dashboard.partner_suppliers'.tr(),
              value: '--',
              change: '--',
            ),
            KpiItem(
              label: 'dashboard.avg_delivery'.tr(),
              value: '--',
              change: '--',
            ),
          ]
        : kpis;

    final icons = [
      Icons.receipt_long_outlined,
      Icons.monetization_on_outlined,
      Icons.factory_outlined,
      Icons.schedule_outlined,
    ];
    final colors = [
      AppColors.primary,
      AppColors.success,
      AppColors.featureTeal,
      AppColors.secondary,
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: List.generate(defaultKpis.length.clamp(0, 4), (i) {
        final kpi = defaultKpis[i];
        final color = colors[i % colors.length];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: color.withValues(alpha: 0.15)),
            boxShadow: AppShadows.cardSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.25)),
                    ),
                    child: Icon(
                      icons[i % icons.length],
                      size: 18,
                      color: color,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: AppRadius.pillBorder,
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      kpi.change,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpi.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    kpi.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChartCard(
    String title,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: AppColors.borderSubtle),
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.2),
                      color.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.headingS),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.more_horiz_rounded,
                  color: AppColors.textPlaceholder,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildOrderTrendChart(DashboardData data) {
    final items = data.orderTrend;
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    final maxVal = items
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${item.count}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: maxVal > 0 ? (item.count / maxVal) * 100 : 0,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      border: Border(
                        top: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.month,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryPieChart(DashboardData data) {
    final categories = data.categories;
    final colors = [
      AppColors.primary,
      AppColors.featureTeal,
      AppColors.secondary,
      AppColors.catPurple,
      AppColors.textPlaceholder,
    ];

    if (categories.isEmpty) {
      return _buildEmptyState();
    }

    return SizedBox(
      height: 130,
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 18,
                    color: AppColors.divider.withValues(alpha: 0.3),
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: categories.isNotEmpty
                        ? categories[0].percent / 100.0
                        : 0,
                    strokeWidth: 18,
                    color: AppColors.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'dashboard.purchase'.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                      Text(
                        'dashboard.distribution'.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length],
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textBody,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors[e.key % colors.length].withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: AppRadius.pillBorder,
                            ),
                            child: Text(
                              '${e.value.percent}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colors[e.key % colors.length],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierRanking(DashboardData data) {
    final suppliers = data.supplierRanking;
    if (suppliers.isEmpty) {
      return _buildEmptyState();
    }
    final rankColors = [
      AppColors.featureYellow,
      AppColors.textSecondary,
      AppColors.secondary,
    ];
    final rankIcons = [
      Icons.looks_one_rounded,
      Icons.looks_two_rounded,
      Icons.looks_3_rounded,
    ];

    return Column(
      children: suppliers.map((s) {
        final isTop3 = s.rank <= 3;
        final rankColor = isTop3
            ? rankColors[(s.rank - 1).clamp(0, 2)]
            : AppColors.textPlaceholder;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isTop3
                  ? rankColor.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: AppRadius.mdBorder,
              border: isTop3
                  ? Border.all(color: rankColor.withValues(alpha: 0.12))
                  : null,
            ),
            child: Row(
              children: [
                if (isTop3)
                  Icon(
                    rankIcons[(s.rank - 1).clamp(0, 2)],
                    size: 22,
                    color: rankColor,
                  )
                else
                  SizedBox(
                    width: 22,
                    child: Center(
                      child: Text(
                        '${s.rank}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPlaceholder,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.name,
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textTitle,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.featureYellow.withValues(alpha: 0.1),
                    borderRadius: AppRadius.pillBorder,
                    border: Border.all(
                      color: AppColors.featureYellow.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.featureYellow,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${s.rating}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.featureYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 64,
                  child: Text(
                    s.amount,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCostBreakdown(DashboardData data) {
    final items = data.costBreakdown;
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    final colors = [
      AppColors.primary,
      AppColors.featureTeal,
      AppColors.secondary,
      AppColors.catPurple,
      AppColors.textPlaceholder,
    ];

    return Column(
      children: items
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      e.value.label,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.divider.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: e.value.ratio,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors[e.key % colors.length],
                                colors[e.key % colors.length].withValues(
                                  alpha: 0.6,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${(e.value.ratio * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors[e.key % colors.length],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 32,
              color: AppColors.textPlaceholder.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'common.no_data'.tr(),
              style: TextStyle(color: AppColors.textPlaceholder, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

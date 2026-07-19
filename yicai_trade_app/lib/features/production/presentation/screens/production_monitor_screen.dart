import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../data/models/monitor_model.dart';
import '../providers/monitor_provider.dart';

/// 生产监控页面 - 对接后端 MonitorController
class ProductionMonitorScreen extends ConsumerStatefulWidget {
  const ProductionMonitorScreen({super.key});

  @override
  ConsumerState<ProductionMonitorScreen> createState() =>
      _ProductionMonitorScreenState();
}

class _ProductionMonitorScreenState
    extends ConsumerState<ProductionMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(monitorProvider.notifier).switchTab(_tabController.index);
      }
    });
    Future.microtask(() => ref.read(monitorProvider.notifier).loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(monitorProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(child: _buildHeroBanner(state)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabBar: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTextStyles.bodyM.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'production.title'.tr()),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('production.alert_center'.tr()),
                        if (state.stats.alerts > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.stats.alerts}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: state.isLoading && state.monitors.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.error != null && state.monitors.isEmpty
            ? Center(
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          ref.read(monitorProvider.notifier).refresh(),
                      child: Text(
                        'common.retry'.tr(),
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [_buildDashboardTab(state), _buildAlertTab(state)],
              ),
      ),
    );
  }

  Widget _buildHeroBanner(MonitorState state) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.featureTeal.withValues(alpha: 0.15),
            AppColors.pageBg,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Production Monitoring',
                      style: AppTextStyles.headingL.copyWith(
                        color: AppColors.featureTeal,
                      ),
                    ),
                    Text(
                      'production.monitor_center_title'.tr(),
                      style: AppTextStyles.bodyS.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _heroStat('${state.stats.monitoring}', 'production.monitoring'.tr()),
              _heroDivider(),
              _heroStat('${state.stats.completed}', 'production.completed'.tr()),
              _heroDivider(),
              _heroStat('${state.stats.alerts}', 'production.active_alerts'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.statNumber.copyWith(
              color: AppColors.featureTeal,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _heroDivider() {
    return Container(width: 1, height: 36, color: AppColors.border);
  }

  // ============ Tab 1: 生产监控 ============
  Widget _buildDashboardTab(MonitorState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(monitorProvider.notifier).refresh(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatsGrid(state.stats),
          const SizedBox(height: 16),
          _buildSectionTitle('production.production_orders'.tr()),
          const SizedBox(height: 8),
          if (state.monitors.isEmpty)
            _buildEmpty('production.no_production'.tr())
          else
            ...state.monitors.map((m) => _buildOrderCard(m)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(MonitorStats stats) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.3,
      children: [
        _statCard(
          Icons.access_time_rounded,
          AppColors.primary,
          'production.tab_monitoring'.tr(),
          '${stats.monitoring}',
        ),
        _statCard(
          Icons.check_circle_outline,
          AppColors.success,
          'production.tab_completed'.tr(),
          '${stats.completed}',
        ),
        _statCard(
          Icons.warning_amber_rounded,
          AppColors.error,
          'production.tab_alerts'.tr(),
          '${stats.alerts}',
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 20, color: color),
          Text(value, style: AppTextStyles.headingL.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildOrderCard(MonitorModel m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(
          color: m.hasAlert
              ? AppColors.error.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.productName,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTitle,
                  ),
                ),
              ),
              if (m.hasAlert)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
              const SizedBox(width: 4),
              Text(
                m.statusLabel,
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${m.orderNo} | ${m.supplierName}',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: m.progress / 100,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                m.progress >= 100
                    ? AppColors.success
                    : m.hasAlert
                    ? AppColors.warning
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${m.progress.toStringAsFixed(0)}%',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
              if (m.expectedDelivery != null)
                Text(
                  'production.expected_delivery_date'.tr(args: ['${m.expectedDelivery!.month}/${m.expectedDelivery!.day}']),
                  style: AppTextStyles.caption,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============ Tab 2: 预警中心 ============
  Widget _buildAlertTab(MonitorState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(monitorProvider.notifier).refreshAlerts(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.alerts.isEmpty)
            _buildEmpty('production.no_alerts'.tr())
          else
            ...state.alerts.map((a) => _buildAlertCard(a)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAlertCard(AlertItem alert) {
    final levelColor = alert.isHigh
        ? AppColors.error
        : alert.level == 'MEDIUM'
        ? AppColors.warning
        : AppColors.featureYellow;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: AppRadius.lgBorder,
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alert.levelLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: levelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alert.typeLabel,
                  style: TextStyle(fontSize: 11, color: AppColors.primary),
                ),
              ),
              const Spacer(),
              if (alert.isPending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'production.pending_process'.tr(),
                    style: TextStyle(fontSize: 11, color: AppColors.warning),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.title,
            style: AppTextStyles.bodyM.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textTitle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.description,
            style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 14,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text(alert.orderNo, style: AppTextStyles.caption),
              const SizedBox(width: 16),
              Icon(
                Icons.store_rounded,
                size: 14,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text(alert.supplierName, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headingS),
      ],
    );
  }

  Widget _buildEmpty(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 48,
              color: AppColors.textPlaceholder.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate({required this.tabBar});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.cardBg, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/router/route_names.dart';
import '../../data/demand_repository.dart';
import '../providers/demand_provider.dart';

/// 需求列表页 - 使用后端真实数据
class DemandListScreen extends ConsumerStatefulWidget {
  const DemandListScreen({super.key});

  @override
  ConsumerState<DemandListScreen> createState() => _DemandListScreenState();
}

class _DemandListScreenState extends ConsumerState<DemandListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      ref.read(myDemandsProvider.notifier).load();
      ref.read(demandListProvider.notifier).loadDemands();
    });
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
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('demand.title'.tr(), style: AppTextStyles.headingM),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.divider,
          tabs: [
            Tab(text: 'demand.my_demands'.tr()),
            Tab(text: 'demand.demand_forum'.tr()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_MyDemandsList(), _DemandForumList()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RouteNames.publishDemand),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'demand.publish'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 我的需求列表 - 真实数据
class _MyDemandsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myDemandsProvider);

    if (state.isLoading && state.demands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.demands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'common.load_failed'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(myDemandsProvider.notifier).refresh(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state.demands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'demand.no_demands'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'demand.publish_first_hint'.tr(),
              style: AppTextStyles.caption,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(myDemandsProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.demands.length,
        itemBuilder: (context, index) =>
            _DemandCard(demand: state.demands[index]),
      ),
    );
  }
}

/// 需求广场 - 真实数据
class _DemandForumList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demandListProvider);

    if (state.isLoading && state.demands.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.demands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'common.load_failed'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => ref.read(demandListProvider.notifier).refresh(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state.demands.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 12),
            Text(
              'demand.no_public_demands'.tr(),
              style: AppTextStyles.bodyM.copyWith(
                color: AppColors.textPlaceholder,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(demandListProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.demands.length,
        itemBuilder: (context, index) =>
            _DemandCard(demand: state.demands[index]),
      ),
    );
  }
}

/// 需求卡片 - 显示真实数据
class _DemandCard extends StatelessWidget {
  final DemandModel demand;
  const _DemandCard({required this.demand});

  Color get _statusColor {
    switch (demand.status) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return AppColors.success;
      case 'PENDING':
        return AppColors.warning;
      case 'CLOSED':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _statusLabel {
    switch (demand.status) {
      case 'ACTIVE':
      case 'PUBLISHED':
        return 'demand.active'.tr();
      case 'PENDING':
        return 'demand.pending_review'.tr();
      case 'CLOSED':
        return 'demand.closed'.tr();
      default:
        return demand.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Expanded(
                child: Text(
                  demand.title,
                  style: AppTextStyles.bodyM.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: AppRadius.pillBorder,
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (demand.description != null && demand.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              demand.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyS.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (demand.demandNo != null) ...[
                Text('${'demand.demand_no_label'.tr()}: ${demand.demandNo}', style: AppTextStyles.caption),
                const SizedBox(width: 12),
              ],
              if (demand.category != null)
                Text('${'demand.category_label'.tr()}: ${demand.category}', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 14, color: AppColors.textPlaceholder),
              const SizedBox(width: 4),
              Text(
                demand.createdAt != null
                    ? '${demand.createdAt!.year}-${demand.createdAt!.month.toString().padLeft(2, '0')}-${demand.createdAt!.day.toString().padLeft(2, '0')}'
                    : 'common.unknown'.tr(),
                style: AppTextStyles.caption,
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.visibility_outlined,
                size: 14,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text('${demand.viewCount}', style: AppTextStyles.caption),
              const SizedBox(width: 16),
              Icon(
                Icons.forum_outlined,
                size: 14,
                color: AppColors.textPlaceholder,
              ),
              const SizedBox(width: 4),
              Text(
                'demand.quote_count'.tr(args: ['${demand.responseCount}']),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

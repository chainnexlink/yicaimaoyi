import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';
import '../providers/auction_provider.dart';
import '../../data/models/auction_model.dart';

/// 反向竞价列表页 - B2B 移动端风格重设计
/// 参考 Alibaba.com / GlobalSources / TradeIndia 移动端竞价布局

// 竞价模块专属配色（蓝紫色调，区别于主色 teal）
class _AuctionColors {
  static const Color accent = Color(0xFF6366F1); // Indigo-500
  static const Color accentLight = Color(0xFF818CF8); // Indigo-400
  static const Color accentDark = Color(0xFF4F46E5); // Indigo-600
  static const Color accentSurface = Color(0x1A6366F1);
  static const Color liveGlow = Color(0x4022C55E);
  static const Color priceDrop = Color(0xFFEF4444);
  static const Color warmOrange = Color(0xFFF59E0B);
}

class AuctionListScreen extends ConsumerStatefulWidget {
  const AuctionListScreen({super.key});

  @override
  ConsumerState<AuctionListScreen> createState() => _AuctionListScreenState();
}

class _AuctionListScreenState extends ConsumerState<AuctionListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> get _tabs => [
    'auction.all'.tr(),
    'auction.bidding'.tr(),
    'auction.waiting'.tr(),
    'auction.ended'.tr(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    Future.microtask(
      () => ref.read(auctionListProvider.notifier).loadAuctions(),
    );
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      const statusList = [null, 'BIDDING', 'PUBLISHED', 'CLOSED'];
      ref
          .read(auctionListProvider.notifier)
          .loadAuctions(status: statusList[_tabController.index]);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: NestedScrollView(
        headerSliverBuilder: _buildSliverHeader,
        body: TabBarView(
          controller: _tabController,
          children: _tabs.map((t) => _AuctionTabBody(tab: t)).toList(),
        ),
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  List<Widget> _buildSliverHeader(
    BuildContext context,
    bool innerBoxIsScrolled,
  ) {
    return [
      SliverAppBar(
        pinned: true,
        floating: true,
        snap: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textTitle,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'auction.title'.tr(),
          style: const TextStyle(
            color: AppColors.textTitle,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auction.use_tab_filter'.tr())),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
            onPressed: () {
              ref.read(auctionListProvider.notifier).loadAuctions();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('auction.list_refreshed'.tr())),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1F2937), width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _AuctionColors.accentLight,
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: _AuctionColors.accent,
              indicatorWeight: 2.5,
              indicatorSize: TabBarIndicatorSize.label,
              dividerHeight: 0,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _tabs.map((t) => Tab(text: t, height: 42)).toList(),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_AuctionColors.accent, _AuctionColors.accentDark],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _AuctionColors.accent.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(RouteNames.auctionCreate),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 6),
                Text(
                  'auction.start_auction'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuctionTabBody extends ConsumerWidget {
  final String tab;
  const _AuctionTabBody({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(auctionListProvider);

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _AuctionColors.accent,
          strokeWidth: 2.5,
        ),
      );
    }

    if (state.error != null && state.auctions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _AuctionColors.accentSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 28,
                color: _AuctionColors.accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'auction.load_failed'.tr(),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.read(auctionListProvider.notifier).refresh(),
              style: TextButton.styleFrom(
                foregroundColor: _AuctionColors.accent,
              ),
              child: Text('auction.click_retry'.tr()),
            ),
          ],
        ),
      );
    }

    final items = state.auctions;
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.gavel_rounded,
                size: 32,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'auction.no_auctions'.tr(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'auction.no_auctions_sub'.tr(),
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(auctionListProvider.notifier).refresh(),
      color: _AuctionColors.accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _AuctionCard(auction: items[i]),
      ),
    );
  }
}

// ==================== 卡片组件 ====================

class _AuctionCard extends StatelessWidget {
  final AuctionModel auction;
  const _AuctionCard({required this.auction});

  bool get _isLive => auction.status == 'BIDDING';
  bool get _isPending =>
      auction.status == 'PUBLISHED' || auction.status == 'PENDING';

  Color get _statusAccent {
    if (_isLive) return const Color(0xFF22C55E);
    if (_isPending) return _AuctionColors.warmOrange;
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/auctions/${auction.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF252D3D), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：状态 + 编号
            _buildHeader(),
            // 标题
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                auction.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF1F5F9),
                  height: 1.35,
                ),
              ),
            ),
            // 数据行
            _buildMetricsRow(),
            // 底部：时间 + 标签
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          // 状态标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLive) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _statusAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _AuctionColors.liveGlow,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  auction.statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _statusAccent,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 编号
          if (auction.auctionNo != null)
            Text(
              auction.auctionNo!,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF4B5563),
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // 当前最低价
          Expanded(
            child: _MetricItem(
              label: 'auction.current_lowest'.tr(),
              value: auction.currentLowest != null
                  ? '\u00a5${auction.currentLowest!.toStringAsFixed(2)}'
                  : '--',
              valueColor: _isLive
                  ? _AuctionColors.priceDrop
                  : const Color(0xFF94A3B8),
              icon: Icons.trending_down_rounded,
              iconColor: _isLive
                  ? _AuctionColors.priceDrop
                  : const Color(0xFF475569),
            ),
          ),
          Container(width: 0.5, height: 32, color: const Color(0xFF252D3D)),
          // 目标价
          Expanded(
            child: _MetricItem(
              label: 'auction.target_price'.tr(),
              value: '\u00a5${auction.targetPrice.toStringAsFixed(2)}',
              valueColor: const Color(0xFF94A3B8),
              icon: Icons.flag_outlined,
              iconColor: const Color(0xFF475569),
            ),
          ),
          Container(width: 0.5, height: 32, color: const Color(0xFF252D3D)),
          // 参与数
          Expanded(
            child: _MetricItem(
              label: 'auction.suppliers'.tr(),
              value: '${auction.bidderCount}${'auction.bidder_unit'.tr()}',
              valueColor: _AuctionColors.accentLight,
              icon: Icons.groups_outlined,
              iconColor: _AuctionColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Row(
        children: [
          // 时间信息
          Icon(
            _isLive ? Icons.timer_outlined : Icons.schedule_outlined,
            size: 14,
            color: _isLive
                ? _AuctionColors.warmOrange
                : const Color(0xFF4B5563),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _isLive
                  ? 'auction.remaining'.tr(args: [auction.timeLeftDisplay])
                  : auction.timeLeftDisplay,
              style: TextStyle(
                fontSize: 12,
                color: _isLive
                    ? _AuctionColors.warmOrange
                    : const Color(0xFF4B5563),
                fontWeight: _isLive ? FontWeight.w500 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 标签
          if (auction.tags.isNotEmpty) ...[
            const SizedBox(width: 8),
            ...auction.tags
                .take(2)
                .map(
                  (tag) => Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _AuctionColors.accentSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _AuctionColors.accentLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
          ],
          // 箭头
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: Color(0xFF374151),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;
  final Color iconColor;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF4B5563),
            height: 1,
          ),
        ),
      ],
    );
  }
}

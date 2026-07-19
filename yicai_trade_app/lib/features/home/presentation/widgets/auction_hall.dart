import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/section_header.dart';

/// 智能采购反向竞价 V2 - 横向滑动卡片，渐变边框
class AuctionHall extends StatelessWidget {
  const AuctionHall({super.key});

  static List<_AuctionItem> get _auctions => [
    _AuctionItem(
      title: 'home.auction_sample_1'.tr(),
      currentLow: '¥12,500',
      factories: 8,
      timeLeft: '02:34:18',
      isActive: true,
    ),
    _AuctionItem(
      title: 'home.auction_sample_2'.tr(),
      currentLow: '¥45,800',
      factories: 5,
      timeLeft: '05:12:40',
      isActive: true,
    ),
    _AuctionItem(
      title: 'home.auction_sample_3'.tr(),
      currentLow: '¥28,200',
      factories: 12,
      timeLeft: '00:45:22',
      isActive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'home.auction_hall_title'.tr(), subtitle: 'home.auction_hall_subtitle'.tr()),
        SizedBox(
          height: 175,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _auctions.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _AuctionCard(auction: _auctions[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => GoRouter.of(context).push(RouteNames.auctionList),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'home.view_all_auctions'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => GoRouter.of(context).push(RouteNames.auctionCreate),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'home.publish_reverse_auction'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuctionItem {
  final String title;
  final String currentLow;
  final int factories;
  final String timeLeft;
  final bool isActive;

  const _AuctionItem({
    required this.title,
    required this.currentLow,
    required this.factories,
    required this.timeLeft,
    required this.isActive,
  });
}

class _AuctionCard extends StatelessWidget {
  final _AuctionItem auction;
  const _AuctionCard({required this.auction});

  @override
  Widget build(BuildContext context) {
    final statusColor = auction.isActive ? AppColors.featureYellow : AppColors.error;

    return Container(
      width: 270,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardBgElevated, AppColors.cardBg],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 顶部状态条
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题行
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        auction.title,
                        style: AppTextStyles.headingS.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        auction.isActive ? 'home.auction_status_ongoing'.tr() : 'home.auction_status_ending'.tr(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 价格
                Row(
                  children: [
                    Text(
                      'home.current_lowest'.tr(),
                      style: AppTextStyles.bodyS.copyWith(fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      auction.currentLow,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 底部信息
                Row(
                  children: [
                    Icon(
                      Icons.factory_outlined,
                      size: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${auction.factories}${'home.factories_participate'.tr()}',
                      style: AppTextStyles.caption.copyWith(fontSize: 11),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      auction.timeLeft,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // CTA
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'home.join_auction'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

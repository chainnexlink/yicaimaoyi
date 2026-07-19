import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/section_header.dart';

/// 反向竞价优势 V3 - 浅色卡片风格
class AuctionAdvantage extends StatelessWidget {
  const AuctionAdvantage({super.key});

  static List<_Advantage> get _advantages => [
    _Advantage(
      num: '01',
      title: 'home.advantage_lower_price'.tr(),
      desc:
          'Multiple factories bid against each other, driving your procurement cost down by 15-30%.',
    ),
    _Advantage(
      num: '02',
      title: 'home.advantage_transparent'.tr(),
      desc:
          '100% transparent online process. No middlemen. Real-time bidding visible to all parties.',
    ),
    _Advantage(
      num: '03',
      title: 'home.advantage_efficient'.tr(),
      desc:
          'Close deals 3x faster. Average bidding cycle: 48 hours from publish to contract.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      children: [
        SectionHeader(title: 'home.auction_advantages_title'.tr(), subtitle: 'home.auction_advantages_subtitle'.tr()),
        if (isTablet)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _advantages
                  .map(
                    (a) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: _AdvantageCard(advantage: a),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _advantages
                  .map(
                    (a) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AdvantageCard(advantage: a),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: Material(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () =>
                    GoRouter.of(context).push(RouteNames.auctionCreate),
                borderRadius: BorderRadius.circular(10),
                child: Center(
                  child: Text(
                    'home.start_reverse_auction'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Advantage {
  final String num;
  final String title;
  final String desc;
  const _Advantage({
    required this.num,
    required this.title,
    required this.desc,
  });
}

class _AdvantageCard extends StatelessWidget {
  final _Advantage advantage;
  const _AdvantageCard({required this.advantage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                advantage.num,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondary.withValues(alpha: 0.7),
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
                  advantage.title,
                  style: AppTextStyles.headingS.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  advantage.desc,
                  style: AppTextStyles.bodyS.copyWith(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/widgets/section_header.dart';

/// 三大核心功能卡片 V3 - 浅色干净风格
class CoreFeatureCards extends StatefulWidget {
  const CoreFeatureCards({super.key});

  @override
  State<CoreFeatureCards> createState() => _CoreFeatureCardsState();
}

class _CoreFeatureCardsState extends State<CoreFeatureCards> {
  final _pageController = PageController(viewportFraction: 0.88);

  static List<_CoreFeature> get _features => [
    _CoreFeature(
      index: 1,
      color: Color(0xFF2563EB),
      titleEn: 'AI Intelligent\nFactory Matching',
      titleCn: 'home.feature_ai_match'.tr(),
      icon: Icons.auto_awesome_rounded,
      bullets: ['home.bullet_ai_1'.tr(), 'home.bullet_ai_2'.tr(), 'home.bullet_ai_3'.tr()],
      cta: 'home.feature_ai_match_cta'.tr(),
      route: RouteNames.smartMatch,
    ),
    _CoreFeature(
      index: 2,
      color: Color(0xFFF97316),
      titleEn: 'Electronic\nAuction',
      titleCn: 'home.feature_reverse_auction'.tr(),
      icon: Icons.gavel_rounded,
      bullets: ['home.bullet_auction_1'.tr(), 'home.bullet_auction_2'.tr(), 'home.bullet_auction_3'.tr()],
      cta: 'home.feature_reverse_auction_cta'.tr(),
      route: RouteNames.auctionList,
    ),
    _CoreFeature(
      index: 3,
      color: Color(0xFF14B8A6),
      titleEn: 'Real-Time Production\nMonitoring',
      titleCn: 'home.feature_production_monitor'.tr(),
      icon: Icons.monitor_heart_outlined,
      bullets: ['home.bullet_monitor_1'.tr(), 'home.bullet_monitor_2'.tr(), 'home.bullet_monitor_3'.tr()],
      cta: 'home.feature_production_monitor_cta'.tr(),
      route: RouteNames.productionMonitor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: 'home.core_services_title'.tr(), subtitle: 'home.core_services_subtitle'.tr()),
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _features.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: _CoreFeatureCard(feature: _features[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        SmoothPageIndicator(
          controller: _pageController,
          count: _features.length,
          effect: WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            activeDotColor: AppColors.primary,
            dotColor: AppColors.border,
            spacing: 8,
          ),
        ),
      ],
    );
  }
}

class _CoreFeature {
  final int index;
  final Color color;
  final String titleEn;
  final String titleCn;
  final IconData icon;
  final List<String> bullets;
  final String cta;
  final String route;

  const _CoreFeature({
    required this.index,
    required this.color,
    required this.titleEn,
    required this.titleCn,
    required this.icon,
    required this.bullets,
    required this.cta,
    required this.route,
  });
}

class _CoreFeatureCard extends StatelessWidget {
  final _CoreFeature feature;

  const _CoreFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 彩色顶条
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: feature.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图标 + 编号
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: feature.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          feature.icon,
                          size: 24,
                          color: feature.color,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: feature.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#${feature.index}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: feature.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 标题
                  Text(
                    feature.titleCn,
                    style: AppTextStyles.headingS.copyWith(
                      color: AppColors.textTitle,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    feature.titleEn,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bullets
                  ...feature.bullets.map(
                    (bullet) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // CTA 按钮
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Material(
                      color: feature.color,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        onTap: () => GoRouter.of(context).push(feature.route),
                        borderRadius: BorderRadius.circular(8),
                        child: Center(
                          child: Text(
                            '${feature.cta} →',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

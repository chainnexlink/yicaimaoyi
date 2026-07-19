import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/router/route_names.dart';

/// 注册成功后的新手引导页 - 介绍三大核心功能
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _maxViewedPage = 0; // 追踪用户已浏览的最远页面

  static List<_FeatureInfo> get _features => [
    _FeatureInfo(
      icon: Icons.auto_awesome,
      title: 'onboarding.title_1'.tr(),
      subtitle: 'onboarding.subtitle_1'.tr(),
      descriptions: [
        'onboarding.desc_1_1'.tr(),
        'onboarding.desc_1_2'.tr(),
        'onboarding.desc_1_3'.tr(),
      ],
      color: AppColors.featureRed,
      lightColor: AppColors.featureRedLight,
      surfaceColor: AppColors.featureRedSurface,
      gradient: AppColors.matchTopBar,
      routeName: RouteNames.smartMatch,
    ),
    _FeatureInfo(
      icon: Icons.gavel_rounded,
      title: 'onboarding.title_2'.tr(),
      subtitle: 'onboarding.subtitle_2'.tr(),
      descriptions: [
        'onboarding.desc_2_1'.tr(),
        'onboarding.desc_2_2'.tr(),
        'onboarding.desc_2_3'.tr(),
      ],
      color: AppColors.featureYellow,
      lightColor: AppColors.featureYellowLight,
      surfaceColor: AppColors.featureYellowSurface,
      gradient: AppColors.auctionTopBar,
      routeName: RouteNames.auctionList,
    ),
    _FeatureInfo(
      icon: Icons.monitor_heart_outlined,
      title: 'onboarding.title_3'.tr(),
      subtitle: 'onboarding.subtitle_3'.tr(),
      descriptions: [
        'onboarding.desc_3_1'.tr(),
        'onboarding.desc_3_2'.tr(),
        'onboarding.desc_3_3'.tr(),
      ],
      color: AppColors.featureTeal,
      lightColor: AppColors.featureTealLight,
      surfaceColor: AppColors.featureTealSurface,
      gradient: AppColors.monitorTopBar,
      routeName: RouteNames.productionMonitor,
    ),
  ];

  void _nextPage() {
    final features = _features;
    if (_currentPage < features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _goHome();
    }
  }

  void _goHome() {
    context.go(RouteNames.home);
  }

  void _goToFeature(String routeName) {
    context.go(routeName);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final features = _features;
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：跳过按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 页码指示器
                  Text(
                    '${_currentPage + 1} / ${features.length}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  // 只有浏览完全部页面后才显示跳过按钮
                  AnimatedOpacity(
                    opacity: _maxViewedPage >= features.length - 1 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: IgnorePointer(
                      ignoring: _maxViewedPage < features.length - 1,
                      child: TextButton(
                        onPressed: _goHome,
                        child: Text(
                          'onboarding.skip_all'.tr(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 中间：功能介绍 PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: features.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                    if (index > _maxViewedPage) _maxViewedPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _FeaturePage(
                    feature: features[index],
                    onTryNow: () => _goToFeature(features[index].routeName),
                  );
                },
              ),
            ),

            // 底部：分页指示器 + 按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // 分页圆点
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(features.length, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? features[_currentPage].color
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // 操作按钮
                  Row(
                    children: [
                      // 跳过当前功能
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentPage < features.length - 1
                              ? _nextPage
                              : _goHome,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage < features.length - 1
                                ? 'onboarding.skip'.tr()
                                : 'onboarding.enter_home'.tr(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 下一步 / 开始使用
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: features[_currentPage].color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentPage < features.length - 1
                                ? 'onboarding.next'.tr()
                                : 'onboarding.get_started'.tr(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单个功能介绍页面
class _FeaturePage extends StatelessWidget {
  final _FeatureInfo feature;
  final VoidCallback onTryNow;

  const _FeaturePage({required this.feature, required this.onTryNow});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // 图标区域
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: feature.gradient,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: feature.color.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(feature.icon, size: 56, color: Colors.white),
          ),
          const SizedBox(height: 32),

          // 标题
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textTitle,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),

          // 副标题
          Text(
            feature.subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // 功能描述列表
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: feature.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: feature.color.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: feature.descriptions.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key < feature.descriptions.length - 1
                        ? 16
                        : 0,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: feature.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textBody,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 立即体验按钮
          TextButton.icon(
            onPressed: onTryNow,
            icon: Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: feature.color,
            ),
            label: Text(
              '${'onboarding.try_now'.tr()} ${feature.title}',
              style: TextStyle(
                color: feature.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// 功能信息数据类
class _FeatureInfo {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> descriptions;
  final Color color;
  final Color lightColor;
  final Color surfaceColor;
  final LinearGradient gradient;
  final String routeName;

  const _FeatureInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.descriptions,
    required this.color,
    required this.lightColor,
    required this.surfaceColor,
    required this.gradient,
    required this.routeName,
  });
}

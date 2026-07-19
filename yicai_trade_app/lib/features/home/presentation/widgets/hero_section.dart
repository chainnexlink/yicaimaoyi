import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';

/// 首页 Hero 区域 - 匹配 Web 端 .hero-banner 样式
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 主标题
          Text(
            'home.hero_title'.tr(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // 副标题
          Text(
            'home.hero_subtitle'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.primaryCyan.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // 统计数字行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatItem(value: '12,000+', label: 'home.stat_factories'.tr()),
              _StatItem(value: '200+', label: 'home.stat_categories'.tr()),
              _StatItem(value: '50+', label: 'home.stat_countries'.tr()),
              _StatItem(value: '15-30%', label: 'home.stat_save_rate'.tr()),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryCyan,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 文本样式预设 V3 - 浅色主题适配
class AppTextStyles {
  AppTextStyles._();

  // ============ 展示标题 ============
  static const TextStyle displayL = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.25,
  );

  // ============ 标题 ============
  static const TextStyle headingL = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textTitle,
    height: 1.3,
  );

  static const TextStyle headingM = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.35,
  );

  static const TextStyle headingS = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
    height: 1.4,
  );

  // ============ 正文 ============
  static const TextStyle bodyL = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.5,
  );

  static const TextStyle bodyM = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.5,
  );

  static const TextStyle bodyS = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.45,
  );

  // ============ 辅助文字 ============
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
    height: 1.4,
  );

  // ============ 按钮 ============
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  // ============ 价格 ============
  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrice,
    height: 1.2,
  );

  static const TextStyle priceL = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrice,
    height: 1.2,
  );

  // ============ 特殊 ============
  static const TextStyle statNumber = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.2,
  );

  static const TextStyle primaryLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.4,
  );

  // ============ 兼容旧代码别名 ============
  static const TextStyle heading1 = headingL;
  static const TextStyle heading2 = headingM;
  static const TextStyle heading3 = headingS;
  static const TextStyle body1 = bodyL;
  static const TextStyle body2 = bodyM;
  static const TextStyle cyanLabel = primaryLabel;
}

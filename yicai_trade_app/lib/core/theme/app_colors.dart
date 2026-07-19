import 'package:flutter/material.dart';

/// 全新色彩系统 V3 - 浅色B2B国际化风格
/// 参考 Alibaba.com / IndiaMART / GlobalSources 配色
class AppColors {
  AppColors._();

  // ============ 品牌主色 (专业蓝) ============
  static const Color primary = Color(0xFF2563EB); // Blue-600
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue-700
  static const Color primaryLight = Color(0xFF60A5FA); // Blue-400
  static const Color primarySurface = Color(0xFFEFF6FF); // Blue-50
  static const Color primaryAlpha10 = Color(0x1A2563EB);
  static const Color primaryAlpha20 = Color(0x332563EB);

  // ============ 品牌辅色 (活力橙 - CTA & 价格) ============
  static const Color secondary = Color(0xFFF97316); // Orange-500
  static const Color secondaryDark = Color(0xFFEA580C); // Orange-600
  static const Color secondaryLight = Color(0xFFFB923C); // Orange-400
  static const Color secondarySurface = Color(0xFFFFF7ED);

  // ============ 三大核心功能色 ============
  static const Color featureRed = Color(0xFFEF4444);
  static const Color featureRedLight = Color(0xFFFCA5A5);
  static const Color featureRedSurface = Color(0xFFFEF2F2);

  static const Color featureYellow = Color(0xFFF59E0B);
  static const Color featureYellowLight = Color(0xFFFCD34D);
  static const Color featureYellowSurface = Color(0xFFFFFBEB);

  static const Color featureTeal = Color(0xFF14B8A6);
  static const Color featureTealLight = Color(0xFF5EEAD4);
  static const Color featureTealSurface = Color(0xFFF0FDFA);

  // ============ 背景色 (浅色主题) ============
  static const Color pageBg = Color(0xFFF5F7FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color cardBgElevated = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color searchBarBg = Color(0xFFF3F4F6);

  // ============ 深色分层背景 (向后兼容) ============
  static const Color darkPageBg = Color(0xFFF5F7FA);
  static const Color darkCardBg = Color(0xFFFFFFFF);
  static const Color darkInputBg = Color(0xFFF3F4F6);
  static const Color darkMonitorBg = Color(0xFFF0F4FF);

  // ============ 文字色 (浅色主题) ============
  static const Color textTitle = Color(0xFF111827); // Gray-900
  static const Color textBody = Color(0xFF374151); // Gray-700
  static const Color textSecondary = Color(0xFF6B7280); // Gray-500
  static const Color textPlaceholder = Color(0xFF9CA3AF); // Gray-400
  static const Color textDisabled = Color(0xFFD1D5DB); // Gray-300
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrice = Color(0xFFF97316);

  // ============ 边框色 ============
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color borderFocus = Color(0xFF2563EB);
  static const Color borderGlow = Color(0x4D2563EB);
  static const Color borderSubtle = Color(0xFFEEF0F4);

  // ============ 状态色 ============
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFF0FDF4);
  static const Color warning = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFEFF6FF);

  // ============ 品类色 ============
  static const Color catBlue = Color(0xFF3B82F6);
  static const Color catOrange = Color(0xFFF97316);
  static const Color catGreen = Color(0xFF16A34A);
  static const Color catPurple = Color(0xFF8B5CF6);
  static const Color catPink = Color(0xFFEC4899);
  static const Color catTeal = Color(0xFF14B8A6);
  static const Color catYellow = Color(0xFFF59E0B);
  static const Color catRed = Color(0xFFEF4444);

  // ============ 渐变 ============
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0F2847)],
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8), Color(0xFF1E40AF)],
  );

  static const LinearGradient profileGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
  );

  static const LinearGradient matchTopBar = LinearGradient(
    colors: [featureRed, featureRedLight],
  );

  static const LinearGradient auctionTopBar = LinearGradient(
    colors: [featureYellow, featureYellowLight],
  );

  static const LinearGradient monitorTopBar = LinearGradient(
    colors: [featureTeal, featureTealLight],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF9FAFB)],
  );

  static const LinearGradient navBarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xF0FFFFFF), Color(0xFFFFFFFF)],
  );

  // ============ 兼容旧代码的别名 ============
  static const Color primaryCyan = primary;
  static const Color primaryCyanDark = primaryDark;
  static const Color primaryCyanLight = primaryLight;
  static const Color primaryCyanAlpha10 = primaryAlpha10;
  static const Color primaryCyanAlpha20 = primaryAlpha20;
  static const Color primaryCyanAlpha30 = Color(0x4D2563EB);
  static const Color bgDark = pageBg;
  static const Color bgDarker = Color(0xFFEEF0F4);
  static const Color bgCard = cardBg;
  static const Color bgCardHover = Color(0xFFF9FAFB);
  static const Color bgInput = searchBarBg;
  static const Color textPrimary = textTitle;
  static const Color textMuted = textSecondary;
  static const Color textHint = textPlaceholder;
  static const Color textOnPrimary2 = textOnPrimary;
  static const Color accentRed = featureRed;
  static const Color accentYellow = featureYellow;
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = featureTeal;
  static const Color accentOrange = secondary;
}

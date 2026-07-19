import 'package:flutter/material.dart';

/// 阴影预设 V3 - 浅色主题自然阴影
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> cardSmall = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> cardMedium = [
    BoxShadow(color: Color(0x12000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> cardLarge = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> buttonPrimary = [
    BoxShadow(color: Color(0x402563EB), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x202563EB), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> glowPrimary = [
    BoxShadow(color: Color(0x332563EB), blurRadius: 20, spreadRadius: 2),
  ];

  static const List<BoxShadow> navBar = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, -2)),
  ];

  static const List<BoxShadow> featureRed = [
    BoxShadow(color: Color(0x20EF4444), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> featureYellow = [
    BoxShadow(color: Color(0x20F59E0B), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> featureTeal = [
    BoxShadow(color: Color(0x2014B8A6), blurRadius: 12, offset: Offset(0, 4)),
  ];
}

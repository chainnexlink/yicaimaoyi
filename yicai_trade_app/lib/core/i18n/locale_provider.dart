import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// 支持的语言列表
class AppLocales {
  AppLocales._();

  static const Locale zh = Locale('zh');
  static const Locale en = Locale('en');
  static const Locale es = Locale('es');

  static const List<Locale> supportedLocales = [zh, en, es];

  static const Map<String, String> localeNames = {
    'zh': '中文',
    'en': 'English',
    'es': 'Espanol',
  };

  static String getLocaleName(Locale locale) {
    return localeNames[locale.languageCode] ?? locale.languageCode;
  }

  /// 切换语言
  static Future<void> changeLocale(BuildContext context, Locale locale) async {
    await context.setLocale(locale);
  }
}

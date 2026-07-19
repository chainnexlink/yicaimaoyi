import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'bootstrap.dart';
import 'app.dart';

void main() async {
  await bootstrap();

  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('zh'), Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('zh'),
      startLocale: const Locale('zh'),
      child: const ProviderScope(child: App()),
    ),
  );
}

import 'package:flutter/material.dart';

/// Logger 工具
class AppLogger {
  static void d(String message) {
    debugPrint('[DEBUG] $message');
  }

  static void i(String message) {
    debugPrint('[INFO] $message');
  }

  static void w(String message) {
    debugPrint('[WARN] $message');
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  Error: $error');
    if (stackTrace != null) debugPrint('  Stack: $stackTrace');
  }
}

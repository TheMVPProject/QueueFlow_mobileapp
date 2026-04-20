import 'package:flutter/foundation.dart';

/// Simple logger utility for the app
/// In production, only logs warnings and errors
/// In debug mode, logs everything
class AppLogger {
  static const String _prefix = '[QueueFlow]';

  /// Log debug information (only in debug mode)
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr 🐛 $message');
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr ℹ️ $message');
    }
  }

  /// Log warnings (always logged)
  static void warning(String message, [String? tag]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagStr ⚠️ $message');
  }

  /// Log errors (always logged)
  static void error(String message, [Object? error, StackTrace? stackTrace, String? tag]) {
    final tagStr = tag != null ? '[$tag]' : '';
    debugPrint('$_prefix$tagStr ❌ $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message, [String? tag]) {
    if (kDebugMode) {
      final tagStr = tag != null ? '[$tag]' : '';
      debugPrint('$_prefix$tagStr ✅ $message');
    }
  }
}

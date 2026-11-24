import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorHandler {
  static const _isProduction =
      String.fromEnvironment('APP_ENVIRONMENT') == 'production';

  /// Report an exception to Sentry with optional context.
  static Future<void> reportException(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
    Map<String, Object?>? data,
  }) async {
    // Dev/staging builds usually run without a Sentry DSN; keep failures
    // visible in `adb logcat` there. Never printed in production builds.
    if (!_isProduction) {
      debugPrint(
        'ErrorHandler: ${operation ?? 'unknown'} failed: '
        '${error.runtimeType}: $error',
      );
      if (stackTrace != null) debugPrint(stackTrace.toString());
    }
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'exception',
        message: operation == null ? error.toString() : '$operation failed',
        level: SentryLevel.error,
        data: {
          if (operation != null) 'operation': operation,
          if (data != null) ...data,
          'error_type': error.runtimeType.toString(),
        },
      ),
    );

    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}

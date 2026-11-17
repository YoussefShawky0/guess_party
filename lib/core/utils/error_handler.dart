import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorHandler {
  /// Report an exception to Sentry with optional context.
  static Future<void> reportException(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
    Map<String, Object?>? data,
  }) async {
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

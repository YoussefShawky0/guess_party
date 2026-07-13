import 'package:sentry_flutter/sentry_flutter.dart';

class ErrorHandler {
  /// Convert technical errors to user-friendly messages in Arabic
  static String getUserFriendlyMessage(String error) {
    final errorLower = error.toLowerCase();

    if (errorLower.contains('cannot vote for yourself') ||
        errorLower.contains('self vote') ||
        errorLower.contains('self-vote')) {
      return 'You cannot vote for yourself';
    }

    if (errorLower.contains('room not found') ||
        errorLower.contains('invalid room code') ||
        errorLower.contains('no rows') ||
        errorLower.contains('pgrst116')) {
      return 'Room not found. Please check the code and try again.';
    }

    if (errorLower.contains('not enough connected players') ||
        errorLower.contains('not enough players') ||
        errorLower.contains('minimum 2 required to skip/advance') ||
        errorLower.contains('minimum 2')) {
      return 'Not enough connected players. Minimum 2 required to skip or advance.';
    }

    // Email confirmation required
    if (errorLower.contains('email not confirmed') ||
        errorLower.contains('confirmation')) {
      return 'Email confirmation required. Check your inbox.';
    }

    // Invalid credentials
    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid_credentials')) {
      return 'Invalid sign-in details';
    }

    // User not found
    if (errorLower.contains('user not found') ||
        errorLower.contains('not_found')) {
      return 'Unable to sign in. Check your details or create an account.';
    }

    // User already exists
    if (errorLower.contains('room is full')) {
      return 'This room is full';
    }

    if (errorLower.contains('room has already started') ||
        errorLower.contains('already started')) {
      return 'This room has already started';
    }

    if (errorLower.contains('user already registered') ||
        errorLower.contains('already exists') ||
        errorLower.contains('duplicate')) {
      return 'An account already uses this email. Try signing in instead.';
    }

    // Weak password
    if (errorLower.contains('password') && errorLower.contains('weak')) {
      return 'Password is too weak. Use at least 8 characters';
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('reconnect') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('failed host lookup') ||
        errorLower.contains('no address associated with hostname') ||
        errorLower.contains('dns')) {
      return 'Connection lost. Reconnecting...';
    }

    // Rate limit
    if (errorLower.contains('rate limit') || errorLower.contains('too many')) {
      return 'Too many attempts. Try again later';
    }

    // Email address invalid
    if (errorLower.contains('email') && errorLower.contains('invalid')) {
      return 'Invalid email address';
    }

    if (errorLower.contains('sign in before upgrading')) {
      return 'Please sign in before upgrading or migrating an account.';
    }

    if (errorLower.contains('already uses a real email')) {
      return 'This account already uses a real email.';
    }

    if (errorLower.contains('verify your email')) {
      return 'Verify your email before setting an account password.';
    }

    if (errorLower.contains('recovery') && errorLower.contains('no longer')) {
      return 'This password recovery link is no longer valid.';
    }

    // Database column errors
    if (errorLower.contains('column') &&
        errorLower.contains('does not exist')) {
      return 'Database error. Check Supabase settings';
    }

    // PostgreSQL errors
    if (errorLower.contains('null value in column')) {
      return 'Required data is missing';
    }

    // Default message - show actual error in debug mode
    return 'An error occurred. Please try again\n(${error.toString().length > 100 ? "${error.toString().substring(0, 100)}..." : error.toString()})';
  }

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
          'error': extractErrorMessage(error),
        },
      ),
    );

    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// Extract clean error message from exception
  static String extractErrorMessage(dynamic error) {
    final errorStr = error.toString();

    // Extract message from AuthApiException
    if (errorStr.contains('message:')) {
      final regex = RegExp(r'message:\s*([^,]+)');
      final match = regex.firstMatch(errorStr);
      if (match != null) {
        return match.group(1)?.trim() ?? errorStr;
      }
    }

    // Extract from Exception
    if (errorStr.startsWith('Exception: ')) {
      return errorStr.replaceFirst('Exception: ', '');
    }

    return errorStr;
  }
}

class ErrorHandler {
  /// Convert technical errors to user-friendly messages in Arabic
  static String getUserFriendlyMessage(String error) {
    final errorLower = error.toLowerCase();

    // Email confirmation required
    if (errorLower.contains('email not confirmed') ||
        errorLower.contains('confirmation')) {
      return 'يجب تأكيد البريد الإلكتروني أولاً. تحقق من بريدك الإلكتروني.';
    }

    // Invalid credentials
    if (errorLower.contains('invalid login credentials') ||
        errorLower.contains('invalid_credentials')) {
      return 'اسم المستخدم أو كلمة المرور غير صحيحة';
    }

    // User not found
    if (errorLower.contains('user not found') ||
        errorLower.contains('not_found')) {
      return 'المستخدم غير موجود. قم بإنشاء حساب أولاً';
    }

    // User already exists
    if (errorLower.contains('user already registered') ||
        errorLower.contains('already exists') ||
        errorLower.contains('duplicate')) {
      return 'اسم المستخدم موجود بالفعل. اختر اسماً آخر';
    }

    // Weak password
    if (errorLower.contains('password') && errorLower.contains('weak')) {
      return 'كلمة المرور ضعيفة. استخدم على الأقل 6 أحرف';
    }

    // Network errors
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout')) {
      return 'خطأ في الاتصال. تحقق من الإنترنت';
    }

    // Rate limit
    if (errorLower.contains('rate limit') || errorLower.contains('too many')) {
      return 'محاولات كثيرة. حاول مرة أخرى بعد قليل';
    }

    // Email address invalid
    if (errorLower.contains('email') && errorLower.contains('invalid')) {
      return 'البريد الإلكتروني غير صحيح';
    }

    // Database column errors
    if (errorLower.contains('column') &&
        errorLower.contains('does not exist')) {
      return 'خطأ في قاعدة البيانات. تحقق من إعدادات Supabase';
    }

    // PostgreSQL errors
    if (errorLower.contains('null value in column')) {
      return 'خطأ في البيانات المطلوبة';
    }

    // Default message - show actual error in debug mode
    return 'حدث خطأ. حاول مرة أخرى\n(${error.toString().length > 100 ? error.toString().substring(0, 100) + "..." : error.toString()})';
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

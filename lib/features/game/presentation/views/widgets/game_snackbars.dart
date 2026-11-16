import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/l10n/l10n.dart';

void _showGameSnackBar(
  BuildContext context, {
  required IconData icon,
  required double iconGap,
  required Widget message,
  required Color backgroundColor,
  required Duration duration,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: AppColors.of(context).textPrimary),
          SizedBox(width: iconGap),
          Expanded(child: message),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

Widget _message(BuildContext context, String text, {double? fontSize}) {
  return Text(
    text,
    style: TextStyle(
      fontSize: fontSize,
      color: AppColors.of(context).textPrimary,
    ),
  );
}

/// Fatal game error (red, 4s).
void showGameErrorSnackBar(BuildContext context, AppErrorCode code) {
  _showGameSnackBar(
    context,
    icon: Icons.error_outline,
    iconGap: 12,
    message: _message(
      context,
      localizedErrorMessage(context.l10n, code),
      fontSize: 16,
    ),
    backgroundColor: AppColors.error,
    duration: const Duration(seconds: 4),
  );
}

/// Non-fatal inline error (warning, 3s).
void showGameWarningSnackBar(BuildContext context, AppErrorCode code) {
  _showGameSnackBar(
    context,
    icon: Icons.info_outline,
    iconGap: 12,
    message: _message(
      context,
      localizedErrorMessage(context.l10n, code),
      fontSize: 16,
    ),
    backgroundColor: AppColors.warning,
    duration: const Duration(seconds: 3),
  );
}

/// Shown after a reconnect completes (success, 2s).
void showBackOnlineSnackBar(BuildContext context) {
  _showGameSnackBar(
    context,
    icon: Icons.wifi,
    iconGap: 10,
    message: _message(context, context.l10n.backOnlineSynced),
    backgroundColor: AppColors.success,
    duration: const Duration(seconds: 2),
  );
}

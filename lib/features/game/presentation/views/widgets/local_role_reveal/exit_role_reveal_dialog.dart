import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Confirms leaving the role reveal. Null when dismissed.
Future<bool?> showExitRoleRevealDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.l10n.exitRoleReveal,
        style: TextStyle(color: AppColors.of(context).textPrimary),
      ),
      content: Text(
        context.l10n.exitRoleRevealMessage,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            context.l10n.stay,
            style: TextStyle(color: AppColors.of(context).textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(context.l10n.exit),
        ),
      ],
    ),
  );
}

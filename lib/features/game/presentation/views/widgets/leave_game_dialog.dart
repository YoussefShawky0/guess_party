import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// "Leave the game?" confirmation. Resolves to false when dismissed.
///
/// [leaveForeground] tints the "Leave" button label (null = theme default).
Future<bool> showLeaveGameDialog(
  BuildContext context, {
  Color? leaveForeground,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.of(context).surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.leaveGameTitle,
                style: TextStyle(color: AppColors.of(context).textPrimary),
              ),
            ],
          ),
          content: Text(
            context.l10n.leaveGameMessage,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                context.l10n.stay,
                style: TextStyle(color: AppColors.of(context).textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: leaveForeground,
              ),
              child: Text(context.l10n.leave),
            ),
          ],
        ),
      ) ??
      false;
}

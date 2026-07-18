import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/l10n/l10n.dart';

typedef DeleteAccountAction = Future<Either<Failure, void>> Function();

Future<void> confirmAccountDeletion({
  required BuildContext context,
  required DeleteAccountAction deleteAccount,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      title: Text(
        context.l10n.deleteAccountTitle,
        style: TextStyle(color: AppColors.of(context).textPrimary),
      ),
      content: Text(
        context.l10n.deleteAccountMessage,
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: Text(context.l10n.deleteAccount),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final result = await deleteAccount();
  if (!context.mounted) return;
  Navigator.of(context).pop();

  result.fold((failure) => _showDeleteError(context, failure.message), (_) {});
}

void _showDeleteError(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      title: Text(
        context.l10n.deleteAccountFailed,
        style: TextStyle(color: AppColors.of(context).textPrimary),
      ),
      content: Text(
        context.l10n.errorWithMessage(message),
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.ok),
        ),
      ],
    ),
  );
}

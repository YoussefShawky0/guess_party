import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/services/update_service.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:in_app_update/in_app_update.dart';

Future<void> checkForUpdates({
  required BuildContext context,
  required AppConfig config,
  required String appVersion,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        context.l10n.checkingForUpdates,
        style: TextStyle(color: AppColors.of(context).textPrimary),
      ),
      content: Row(
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              context.l10n.pleaseWait,
              style: TextStyle(color: AppColors.of(context).textSecondary),
            ),
          ),
        ],
      ),
    ),
  );

  final updateInfo = await UpdateService.checkForUpdate(config);
  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (updateInfo == null) {
    _showUpdateErrorDialog(context);
  } else if (updateInfo.updateAvailability ==
      UpdateAvailability.updateAvailable) {
    _showUpdateAvailableDialog(context, updateInfo, config);
  } else {
    _showUpToDateDialog(context, appVersion);
  }
}

void _showUpToDateDialog(BuildContext context, String appVersion) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.circleCheck,
            color: AppColors.success,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.upToDate,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ),
        ],
      ),
      content: Text(
        context.l10n.latestVersionMessage(appVersion),
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 16,
        ),
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

void _showUpdateAvailableDialog(
  BuildContext context,
  AppUpdateInfo updateInfo,
  AppConfig config,
) {
  final canImmediate = updateInfo.immediateUpdateAllowed;
  final canFlexible = updateInfo.flexibleUpdateAllowed;
  if (!canImmediate && !canFlexible) {
    _showUpdateErrorDialog(context);
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.updateAvailable,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ),
        ],
      ),
      content: Text(
        context.l10n.playStoreUpdateMessage,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 16,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(context.l10n.later),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            if (canImmediate) {
              UpdateService.performImmediateUpdate(config);
            } else {
              UpdateService.startFlexibleUpdate(config);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text(
            canImmediate ? context.l10n.updateNow : context.l10n.update,
          ),
        ),
      ],
    ),
  );
}

void _showUpdateErrorDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: AppColors.of(context).surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.triangleExclamation,
            color: AppColors.warning,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.updateCheckFailed,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ),
        ],
      ),
      content: Text(
        context.l10n.updateCheckFailedMessage,
        style: TextStyle(
          color: AppColors.of(context).textSecondary,
          fontSize: 16,
        ),
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

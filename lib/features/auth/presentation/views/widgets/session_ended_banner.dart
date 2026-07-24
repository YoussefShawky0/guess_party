import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class SessionEndedBanner extends StatelessWidget {
  const SessionEndedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('session-ended-message'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.l10n.sessionEnded,
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.of(context).textSecondary),
      ),
    );
  }
}

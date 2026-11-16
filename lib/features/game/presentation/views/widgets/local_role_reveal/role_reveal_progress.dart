import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// "Player N of M" label plus progress bar.
class RoleRevealProgress extends StatelessWidget {
  final int currentIndex;
  final int total;
  final bool isTablet;

  const RoleRevealProgress({
    super.key,
    required this.currentIndex,
    required this.total,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.playerProgress(currentIndex + 1, total),
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: isTablet ? 18 : 14,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: (currentIndex + 1) / total,
          backgroundColor: AppColors.of(context).surface,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: isTablet ? 8 : 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

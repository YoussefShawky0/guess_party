import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class RoleRevealLoading extends StatelessWidget {
  final bool isTablet;

  const RoleRevealLoading({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            context.l10n.loadingSharedSession,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

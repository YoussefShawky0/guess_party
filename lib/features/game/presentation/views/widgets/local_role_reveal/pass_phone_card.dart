import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Pass-the-phone step: shows who the device goes to, role still hidden.
class PassPhoneCard extends StatelessWidget {
  final Player player;
  final bool isTablet;

  const PassPhoneCard({
    super.key,
    required this.player,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 48 : 32),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            FontAwesomeIcons.handPointRight,
            color: AppColors.primary,
            size: isTablet ? 64 : 48,
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            context.l10n.passPhoneTo,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 22 : 18,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            player.username,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: isTablet ? 42 : 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FaIcon(
                  FontAwesomeIcons.eyeSlash,
                  color: AppColors.warning,
                  size: isTablet ? 20 : 16,
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.protectRole,
                  style: TextStyle(
                    color: AppColors.warning,
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

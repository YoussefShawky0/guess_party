import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/shared/widgets/directional_fa_icon.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Reveal / next player / start game button.
class RoleRevealActionButton extends StatelessWidget {
  final bool isRoleRevealed;
  final bool isLastPlayer;
  final bool isTablet;
  final VoidCallback onPressed;

  const RoleRevealActionButton({
    super.key,
    required this.isRoleRevealed,
    required this.isLastPlayer,
    required this.isTablet,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRoleRevealed
              ? (isLastPlayer ? AppColors.success : AppColors.primary)
              : AppColors.primary,
          padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Only the "next player" arrow is directional; play and eye are not.
            if (isRoleRevealed && !isLastPlayer)
              DirectionalFaIcon(
                FontAwesomeIcons.arrowRight,
                size: isTablet ? 24 : 20,
                color: AppColors.of(context).textPrimary,
              )
            else
              FaIcon(
                isRoleRevealed ? FontAwesomeIcons.play : FontAwesomeIcons.eye,
                size: isTablet ? 24 : 20,
                color: AppColors.of(context).textPrimary,
              ),
            const SizedBox(width: 12),
            Text(
              isRoleRevealed
                  ? (isLastPlayer
                        ? context.l10n.startGameExclamation
                        : context.l10n.nextPlayer)
                  : context.l10n.revealMyRole,
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.of(context).textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

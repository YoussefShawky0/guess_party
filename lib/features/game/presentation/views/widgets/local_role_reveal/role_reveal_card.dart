import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Reveal step: the player's secret role (imposter or character).
class RoleRevealCard extends StatelessWidget {
  final Player player;
  final bool isImposter;
  final Character character;
  final bool isTablet;

  const RoleRevealCard({
    super.key,
    required this.player,
    required this.isImposter,
    required this.character,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isImposter ? AppColors.error : AppColors.success;
    final roleIcon = isImposter
        ? FontAwesomeIcons.userSecret
        : FontAwesomeIcons.userCheck;

    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 32),
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.6), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name
          Text(
            player.username,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Role icon in circle
          Container(
            padding: EdgeInsets.all(isTablet ? 28 : 24),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: FaIcon(roleIcon, color: accent, size: isTablet ? 56 : 48),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // "You are the" text
          Text(
            context.l10n.youAreThe,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          const SizedBox(height: 8),

          // Role name
          Text(
            isImposter
                ? context.l10n.imposterUpper
                : context.l10n.innocentUpper,
            style: TextStyle(
              color: accent,
              fontSize: isTablet ? 36 : 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Bottom hint box
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 14 : 12,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isImposter) ...[
                  Text(
                    character.emoji,
                    style: TextStyle(fontSize: isTablet ? 24 : 20),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      character.displayName(
                        Localizations.localeOf(context).languageCode,
                      ),
                      style: TextStyle(
                        color: accent,
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ] else ...[
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    color: accent,
                    size: isTablet ? 20 : 18,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      context.l10n.blendIn,
                      style: TextStyle(
                        color: accent,
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

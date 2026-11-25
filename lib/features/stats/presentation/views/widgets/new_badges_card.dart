import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/presentation/badge_visuals.dart';
import 'package:guess_party/l10n/l10n.dart';

/// "New badge unlocked!" card shown on Game Over.
class NewBadgesCard extends StatelessWidget {
  final Set<BadgeId> badges;

  const NewBadgesCard({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ordered = [
      for (final id in BadgeId.values)
        if (badges.contains(id)) id,
    ];
    return Container(
      key: const Key('new-badges-card'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldMedal.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.newBadgeUnlocked,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final id in ordered)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(id.icon, size: 18, color: AppColors.goldMedal),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        id.localizedName(context.l10n),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

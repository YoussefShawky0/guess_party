import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';

/// "{host} wants to play again" card shown on Game Over to invited players.
class RematchInviteCard extends StatelessWidget {
  final String hostName;
  final bool isJoining;
  final VoidCallback onJoin;
  final VoidCallback onDecline;

  const RematchInviteCard({
    super.key,
    required this.hostName,
    required this.isJoining,
    required this.onJoin,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      key: const Key('rematch-invite-card'),
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.rematchInviteTitle(hostName),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.rematchInviteBody,
            style: TextStyle(color: colors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  key: const Key('rematch-decline'),
                  label: context.l10n.rematchDecline,
                  variant: GameButtonVariant.secondary,
                  size: GameButtonSize.md,
                  onPressed: isJoining ? null : onDecline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GameButton(
                  key: const Key('rematch-join'),
                  label: context.l10n.rematchJoin,
                  size: GameButtonSize.md,
                  isLoading: isJoining,
                  onPressed: isJoining ? null : onJoin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

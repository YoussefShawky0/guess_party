import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

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
                child: OutlinedButton(
                  onPressed: isJoining ? null : onDecline,
                  child: Text(context.l10n.rematchDecline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isJoining ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: colors.textPrimary,
                  ),
                  child: isJoining
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.textPrimary,
                          ),
                        )
                      : Text(context.l10n.rematchJoin),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

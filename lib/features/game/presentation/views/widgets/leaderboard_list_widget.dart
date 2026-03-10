import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class LeaderboardListWidget extends StatelessWidget {
  /// Players ranked 4th and below, sorted by score descending.
  final List<Player> players;
  final Map<String, int> playerScores;

  /// Rank number offset (default 4 for the 4th place onward).
  final int startRank;

  const LeaderboardListWidget({
    super.key,
    required this.players,
    required this.playerScores,
    this.startRank = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox();

    return Column(
      children: List.generate(players.length, (index) {
        final player = players[index];
        final rank = startRank + index;
        final score = playerScores[player.id] ?? 0;
        final initial = player.username.isNotEmpty
            ? player.username[0].toUpperCase()
            : '?';
        final avatarColor = AppColors.getAvatarColor(rank - 1);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    rank.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarColor,
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Name + score
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.username,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$score points',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Decorative chevron
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.textMuted,
                size: 22,
              ),
            ],
          ),
        );
      }),
    );
  }
}

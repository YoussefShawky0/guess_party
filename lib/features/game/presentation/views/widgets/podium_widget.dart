import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class PodiumWidget extends StatelessWidget {
  /// Top 3 players already sorted by score descending (index 0 = 1st place)
  final List<Player> topPlayers;
  final Map<String, int> playerScores;

  const PodiumWidget({
    super.key,
    required this.topPlayers,
    required this.playerScores,
  });

  @override
  Widget build(BuildContext context) {
    final first = topPlayers.isNotEmpty ? topPlayers[0] : null;
    final second = topPlayers.length > 1 ? topPlayers[1] : null;
    final third = topPlayers.length > 2 ? topPlayers[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd place — left
        Expanded(
          child: second != null
              ? _PodiumBar(
                  player: second,
                  rank: 2,
                  score: playerScores[second.id] ?? 0,
                  barHeight: 148,
                  barColor: AppColors.of(context).surfaceLight,
                  medalColor: AppColors.silverMedal,
                  avatarIndex: 1,
                )
              : const SizedBox(),
        ),
        // 1st place — center (tallest)
        Expanded(
          child: first != null
              ? _PodiumBar(
                  player: first,
                  rank: 1,
                  score: playerScores[first.id] ?? 0,
                  barHeight: 190,
                  barColor: AppColors.primary,
                  medalColor: AppColors.goldMedal,
                  avatarIndex: 0,
                  showCrown: true,
                )
              : const SizedBox(),
        ),
        // 3rd place — right (shortest)
        Expanded(
          child: third != null
              ? _PodiumBar(
                  player: third,
                  rank: 3,
                  score: playerScores[third.id] ?? 0,
                  barHeight: 112,
                  barColor: AppColors.primaryDark,
                  medalColor: AppColors.bronzeMedal,
                  avatarIndex: 2,
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

class _PodiumBar extends StatelessWidget {
  final Player player;
  final int rank;
  final int score;
  final double barHeight;
  final Color barColor;
  final Color medalColor;
  final int avatarIndex;
  final bool showCrown;

  const _PodiumBar({
    required this.player,
    required this.rank,
    required this.score,
    required this.barHeight,
    required this.barColor,
    required this.medalColor,
    required this.avatarIndex,
    this.showCrown = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = player.username.isNotEmpty
        ? player.username[0].toUpperCase()
        : '?';
    final avatarColor = AppColors.getAvatarColor(avatarIndex);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Score badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.scoreBadgeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: rank == 1 ? AppColors.scoreBadgeText : medalColor,
                size: 9,
              ),
              const SizedBox(width: 4),
              Text(
                '$score',
                style: TextStyle(
                  color: AppColors.scoreBadgeText,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Crown for 1st place
        if (showCrown)
          Icon(Icons.workspace_premium, color: AppColors.goldMedal, size: 26)
        else
          const SizedBox(height: 26),
        const SizedBox(height: 4),
        // Avatar circle
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
            border: Border.all(color: medalColor, width: 2.5),
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        // Podium bar
        Container(
          width: double.infinity,
          height: barHeight,
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                child: Text(
                  player.username,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

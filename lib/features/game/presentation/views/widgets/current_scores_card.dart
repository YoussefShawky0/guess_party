import 'package:flutter/material.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class CurrentScoresCard extends StatelessWidget {
  final List<Player> players;
  final Map<String, int> playerScores;
  final String imposterPlayerId;

  const CurrentScoresCard({
    super.key,
    required this.players,
    required this.playerScores,
    required this.imposterPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Sort players by score (descending)
    final sortedPlayers = List<Player>.from(players)
      ..sort((a, b) {
        final scoreA = playerScores[a.id] ?? 0;
        final scoreB = playerScores[b.id] ?? 0;
        return scoreB.compareTo(scoreA);
      });

    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber,
                  size: isTablet ? 32 : 24,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Current Scores',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: isTablet ? 24 : 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            ...sortedPlayers.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              final score = playerScores[player.id] ?? 0;
              final isImposter = player.id == imposterPlayerId;

              return Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                child: _ScoreRow(
                  rank: index + 1,
                  player: player,
                  score: score,
                  isImposter: isImposter,
                  isTablet: isTablet,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final int rank;
  final Player player;
  final int score;
  final bool isImposter;
  final bool isTablet;

  const _ScoreRow({
    required this.rank,
    required this.player,
    required this.score,
    required this.isImposter,
    required this.isTablet,
  });

  Color _getRankColor() {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return Colors.blue.shade100;
    }
  }

  IconData? _getRankIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events;
      case 2:
        return Icons.workspace_premium;
      case 3:
        return Icons.military_tech;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: isTablet ? 40 : 32,
          height: isTablet ? 40 : 32,
          decoration: BoxDecoration(
            color: _getRankColor(),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _getRankIcon() != null
                ? Icon(
                    _getRankIcon(),
                    color: Colors.white,
                    size: isTablet ? 24 : 18,
                  )
                : Text(
                    '$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: isTablet ? 18 : 14,
                    ),
                  ),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        CircleAvatar(
          radius: isTablet ? 22 : 18,
          child: Text(
            player.username[0].toUpperCase(),
            style: TextStyle(fontSize: isTablet ? 20 : 16),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Expanded(
          child: Text(
            player.username,
            style: TextStyle(
              fontWeight: isImposter ? FontWeight.bold : FontWeight.normal,
              fontSize: isTablet ? 18 : 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$score pts',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
        ),
      ],
    );
  }
}

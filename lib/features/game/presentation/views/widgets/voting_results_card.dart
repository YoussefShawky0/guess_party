import 'package:flutter/material.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class VotingResultsCard extends StatelessWidget {
  final Map<String, int> voteCounts;
  final List<Player> players;
  final String imposterPlayerId;
  final Player? mostVotedPlayer;
  final int maxVotes;

  const VotingResultsCard({
    super.key,
    required this.voteCounts,
    required this.players,
    required this.imposterPlayerId,
    required this.mostVotedPlayer,
    required this.maxVotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (mostVotedPlayer == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voting Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: isTablet ? 24 : 20,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Container(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Most voted player: ${mostVotedPlayer!.username} ($maxVotes votes)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            ...voteCounts.entries.map((entry) {
              final player = players.firstWhere((p) => p.id == entry.key);
              final isImposter = entry.key == imposterPlayerId;

              return Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
                child: _VoteResultRow(
                  player: player,
                  voteCount: entry.value,
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

class _VoteResultRow extends StatelessWidget {
  final Player player;
  final int voteCount;
  final bool isImposter;
  final bool isTablet;

  const _VoteResultRow({
    required this.player,
    required this.voteCount,
    required this.isImposter,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: isTablet ? 20 : 16,
                backgroundColor: isImposter
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                child: Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(
                    color: isImposter ? Colors.red : Colors.blue,
                    fontSize: isTablet ? 18 : 14,
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Flexible(
                child: Text(
                  player.username,
                  style: TextStyle(
                    fontWeight: isImposter
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: isTablet ? 18 : 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isImposter)
                Padding(
                  padding: EdgeInsets.only(left: isTablet ? 12 : 8),
                  child: Icon(
                    Icons.star,
                    size: isTablet ? 20 : 16,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 12,
            vertical: isTablet ? 8 : 4,
          ),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$voteCount votes',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

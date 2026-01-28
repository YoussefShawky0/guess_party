import 'package:flutter/material.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/views/widgets/imposter_reveal_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting_results_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/current_scores_card.dart';

class ResultsPhaseContent extends StatelessWidget {
  final RoundInfo roundInfo;
  final List<Player> players;
  final Map<String, int> playerScores;
  final Map<String, int> voteCounts;
  final VoidCallback onNextRound;
  final bool isHost;

  const ResultsPhaseContent({
    super.key,
    required this.roundInfo,
    required this.players,
    required this.playerScores,
    required this.voteCounts,
    required this.onNextRound,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Find imposter
    final imposter = players.firstWhere(
      (p) => p.id == roundInfo.imposterPlayerId,
      orElse: () => players.first,
    );

    // Calculate if imposter was caught
    final maxVotes = voteCounts.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    final mostVotedPlayerId = voteCounts.entries
        .firstWhere(
          (entry) => entry.value == maxVotes,
          orElse: () => const MapEntry('', 0),
        )
        .key;
    final imposterCaught = mostVotedPlayerId == roundInfo.imposterPlayerId;

    final mostVotedPlayer = mostVotedPlayerId.isNotEmpty
        ? players.firstWhere(
            (p) => p.id == mostVotedPlayerId,
            orElse: () => players.first,
          )
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imposter Reveal
          ImposterRevealCard(
            imposter: imposter,
            imposterCaught: imposterCaught,
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Voting Results
          VotingResultsCard(
            voteCounts: voteCounts,
            players: players,
            imposterPlayerId: roundInfo.imposterPlayerId,
            mostVotedPlayer: mostVotedPlayer,
            maxVotes: maxVotes,
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Current Scores
          CurrentScoresCard(
            players: players,
            playerScores: playerScores,
            imposterPlayerId: roundInfo.imposterPlayerId,
          ),
          SizedBox(height: isTablet ? 32 : 24),

          // Next Round Button (only for host)
          if (isHost)
            ElevatedButton(
              onPressed: onNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Start Next Round',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
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
  final VoidCallback? onGameEnd;
  final bool isHost;
  final bool isLastRound;
  final int totalRounds;

  const ResultsPhaseContent({
    super.key,
    required this.roundInfo,
    required this.players,
    required this.playerScores,
    required this.voteCounts,
    required this.onNextRound,
    this.onGameEnd,
    required this.isHost,
    this.isLastRound = false,
    this.totalRounds = 5,
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

          // Last Round - Show Winner and Exit
          if (isLastRound) ...[
            _buildWinnerCard(context, isTablet),
            SizedBox(height: isTablet ? 20 : 16),
            ElevatedButton.icon(
              onPressed: () {
                onGameEnd?.call();
                context.go('/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.home, size: isTablet ? 24 : 20),
              label: Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else if (isHost)
            // Next Round Button (only for host, not on last round)
            ElevatedButton(
              onPressed: onNextRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.textPrimary,
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

  Widget _buildWinnerCard(BuildContext context, bool isTablet) {
    // Get winner (highest score)
    final sortedPlayers = List<Player>.from(players);
    sortedPlayers.sort(
      (a, b) => (playerScores[b.id] ?? 0).compareTo(playerScores[a.id] ?? 0),
    );
    final winner = sortedPlayers.first;
    final winnerScore = playerScores[winner.id] ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.goldMedal.withOpacity(0.3),
            AppColors.goldMedal.withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldMedal, width: 3),
      ),
      padding: EdgeInsets.all(isTablet ? 32 : 24),
      child: Column(
        children: [
          FaIcon(
            FontAwesomeIcons.trophy,
            size: isTablet ? 64 : 48,
            color: AppColors.goldMedal,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            '🎉 Game Over! 🎉',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Winner',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 4),
          Text(
            winner.username,
            style: TextStyle(
              fontSize: isTablet ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.goldMedal,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 4),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.goldMedal,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$winnerScore points',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

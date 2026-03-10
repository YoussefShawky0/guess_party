import 'package:flutter/material.dart';
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

          // Last Round - Host ends game and goes to leaderboard
          if (isLastRound && isHost)
            ElevatedButton.icon(
              onPressed: () => onGameEnd?.call(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldMedal,
                foregroundColor: AppColors.scoreBadgeText,
                padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(Icons.leaderboard_rounded, size: isTablet ? 24 : 20),
              label: Text(
                'View Final Leaderboard',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isLastRound && !isHost)
            _buildWaitingMessage(
              'Waiting for host to show leaderboard...',
              AppColors.goldMedal,
              AppColors.goldMedal.withOpacity(0.4),
              isTablet,
            )
          else if (!isLastRound && isHost)
            // Next Round Button (only for host)
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
            )
          else if (!isLastRound && !isHost)
            _buildWaitingMessage(
              'Waiting for host to start next round...',
              AppColors.primary,
              AppColors.cardBorder,
              isTablet,
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingMessage(
    String text,
    Color indicatorColor,
    Color borderColor,
    bool isTablet,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isTablet ? 18 : 14,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: indicatorColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

import 'current_scores_card.dart';
import 'imposter_reveal_card.dart';
import 'voting_results_card.dart';

class SharedDeviceIntroCard extends StatelessWidget {
  final bool isTablet;

  const SharedDeviceIntroCard({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('shared-device-neutral-card'),
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1.5),
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_rounded,
            size: isTablet ? 54 : 42,
            color: AppColors.of(context).textSecondary,
          ),
          SizedBox(height: isTablet ? 12 : 10),
          Text(
            'Shared game screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Continue the round on the shared device.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class SharedDeviceHintsContent extends StatelessWidget {
  final bool isTablet;

  const SharedDeviceHintsContent({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('shared-device-hints-content'),
      decoration: BoxDecoration(
        color: AppColors.of(context).hintCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).hintCardBorder,
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          Icon(
            Icons.people,
            size: isTablet ? 64 : 48,
            color: AppColors.of(context).characterCardIcon,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Discuss and give hints verbally!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Talk about the character without revealing yourself. The timer will move to voting automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class SharedDeviceVotingContent extends StatelessWidget {
  final RoundInfo round;
  final List<Player> players;
  final bool isTablet;
  final bool isFinalizing;
  final ValueChanged<String> onSelectVoter;
  final VoidCallback onShowResults;

  const SharedDeviceVotingContent({
    super.key,
    required this.round,
    required this.players,
    required this.isTablet,
    required this.isFinalizing,
    required this.onSelectVoter,
    required this.onShowResults,
  });

  @override
  Widget build(BuildContext context) {
    final progress = round.requiredVoteCount <= 0
        ? 0.0
        : (round.submittedVoteCount / round.requiredVoteCount)
              .clamp(0.0, 1.0)
              .toDouble();

    return Column(
      key: const Key('shared-device-voting-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Voting Phase',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Find the Impostor! Each player taps their own name, then picks who they suspect.',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).cardBorder),
          ),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap your name to vote ↓',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              SizedBox(height: isTablet ? 16 : 12),
              ...players.map(
                (player) => SharedDeviceVotePlayerTile(
                  player: player,
                  voteCount: round.voteCounts[player.id] ?? 0,
                  hasAlreadyVotedAsVoter: round.playerVotes.containsKey(
                    player.id,
                  ),
                  isTablet: isTablet,
                  onVote: () => onSelectVoter(player.id),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).cardBorder),
          ),
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Votes (${round.submittedVoteCount}/${round.requiredVoteCount})',
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              SizedBox(height: isTablet ? 12 : 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: isTablet ? 12 : 8,
                  backgroundColor: AppColors.of(context).surfaceLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (round.allRequiredVotesSubmitted) ...[
          SizedBox(height: isTablet ? 16 : 12),
          ElevatedButton.icon(
            onPressed: isFinalizing ? null : onShowResults,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              isFinalizing ? 'Finalizing Results...' : 'Show Results Now →',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.of(context).textPrimary,
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ],
    );
  }
}

class SharedDeviceResultsContent extends StatelessWidget {
  final GameLoaded state;
  final bool isTablet;
  final bool isStartingNextRound;
  final VoidCallback onFinishGame;
  final VoidCallback onStartNextRound;

  const SharedDeviceResultsContent({
    super.key,
    required this.state,
    required this.isTablet,
    required this.isStartingNextRound,
    required this.onFinishGame,
    required this.onStartNextRound,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final imposterId = round.imposterPlayerId;
    if (imposterId == null || round.character == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final imposter = gameState.players
        .where((player) => player.id == imposterId)
        .firstOrNull;
    if (imposter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxVotes = round.voteCounts.values.fold<int>(
      0,
      (maximum, count) => count > maximum ? count : maximum,
    );
    final leaders = round.voteCounts.entries
        .where((entry) => maxVotes > 0 && entry.value == maxVotes)
        .toList(growable: false);
    final mostVotedId = leaders.length == 1 ? leaders.single.key : null;
    final mostVotedPlayer = gameState.players
        .where((player) => player.id == mostVotedId)
        .firstOrNull;

    return Column(
      key: const Key('shared-device-results-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImposterRevealCard(
          imposter: imposter,
          imposterCaught: mostVotedId == imposterId,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        VotingResultsCard(
          voteCounts: round.voteCounts,
          players: gameState.players,
          imposterPlayerId: imposterId,
          mostVotedPlayer: mostVotedPlayer,
          maxVotes: maxVotes,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        CurrentScoresCard(
          players: gameState.players,
          playerScores: gameState.playerScores,
          imposterPlayerId: imposterId,
        ),
        SizedBox(height: isTablet ? 32 : 24),
        ElevatedButton.icon(
          onPressed: gameState.isLastRound
              ? onFinishGame
              : (isStartingNextRound ? null : onStartNextRound),
          icon: Icon(
            gameState.isLastRound
                ? Icons.leaderboard_rounded
                : Icons.navigate_next,
          ),
          label: Text(
            gameState.isLastRound
                ? 'View Final Leaderboard'
                : (isStartingNextRound
                      ? 'Creating Round...'
                      : 'Start Next Round'),
          ),
        ),
      ],
    );
  }
}

class SharedDeviceVotePlayerTile extends StatelessWidget {
  final Player player;
  final int voteCount;
  final bool hasAlreadyVotedAsVoter;
  final bool isTablet;
  final VoidCallback onVote;

  const SharedDeviceVotePlayerTile({
    super.key,
    required this.player,
    required this.voteCount,
    required this.hasAlreadyVotedAsVoter,
    required this.isTablet,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: hasAlreadyVotedAsVoter
              ? AppColors.voteSelectedBg
              : AppColors.of(context).voteUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAlreadyVotedAsVoter
                ? AppColors.success
                : AppColors.of(context).cardBorder,
            width: hasAlreadyVotedAsVoter ? 2 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            key: Key('shared-device-voter-${player.id}'),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 8 : 4,
            ),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: isTablet ? 24 : 20,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    player.username[0].toUpperCase(),
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: isTablet ? 20 : 16,
                    ),
                  ),
                ),
                if (voteCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: isTablet ? 22 : 18,
                      height: isTablet ? 22 : 18,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.of(context).surface,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$voteCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 12 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              player.username,
              style: TextStyle(
                color: AppColors.of(context).textPrimary,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            subtitle: voteCount > 0
                ? Text(
                    voteCount == 1 ? '1 vote' : '$voteCount votes',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: isTablet ? 13 : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : null,
            trailing: hasAlreadyVotedAsVoter
                ? FaIcon(
                    FontAwesomeIcons.circleCheck,
                    color: AppColors.success,
                    size: isTablet ? 28 : 22,
                  )
                : ElevatedButton(
                    onPressed: onVote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.of(context).textPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                        vertical: isTablet ? 12 : 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Vote',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

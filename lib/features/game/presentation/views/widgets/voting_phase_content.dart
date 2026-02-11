import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

class VotingPhaseContent extends StatelessWidget {
  final RoundInfo round;
  final List<Player> players;
  final String gameMode;
  final String currentUserId;

  const VotingPhaseContent({
    super.key,
    required this.round,
    required this.players,
    required this.gameMode,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Find current player
    final currentPlayer = players.firstWhere(
      (p) => p.userId == currentUserId,
      orElse: () => players.first,
    );
    
    // In local mode, check if ALL players have voted (not just current player)
    // In online mode, check if current player has voted
    final hasVoted = gameMode == 'local'
        ? round.playerVotes.length >= players.length  // All players voted
        : round.playerVotes.containsKey(currentPlayer.id);  // Current player voted

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(context, isTablet),
        SizedBox(height: isTablet ? 12 : 8),
        _buildDescription(context, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        if (gameMode == 'local' || !hasVoted)
          _buildVotingList(context, isTablet, currentPlayer, hasVoted)
        else
          _buildVoteSubmittedCard(context, isTablet),
        SizedBox(height: isTablet ? 20 : 16),
        _buildVotingProgress(context, isTablet),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isTablet) {
    return Text(
      'Voting Phase',
      style: TextStyle(
        fontSize: isTablet ? 24 : 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDescription(BuildContext context, bool isTablet) {
    return Text(
      gameMode == 'local'
          ? 'Pass the phone - each player votes for who they think is the Impostor!'
          : 'Vote for who you think is the Impostor!',
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: isTablet ? 16 : 14,
      ),
    );
  }

  Widget _buildVotingList(
    BuildContext context,
    bool isTablet,
    Player currentPlayer,
    bool hasVoted,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gameMode == 'local' ? 'Select player to vote:' : 'Choose player:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...players.map((player) {
            // In online mode only: hide current user to prevent self-voting
            // In local mode: show all players (voting happens through dialog)
            if (gameMode == 'online' && player.userId == currentUserId) {
              return const SizedBox.shrink();
            }

            final hasVotedForThisPlayer =
                gameMode == 'online' &&
                round.playerVotes[currentPlayer.id] == player.id;

            return _VotePlayerTile(
              player: player,
              isVotedFor: hasVotedForThisPlayer,
              isTablet: isTablet,
              onVote: () => _handleVote(
                context,
                player,
                currentPlayer,
                hasVoted,
                hasVotedForThisPlayer,
              ),
            );
          }),
        ],
      ),
    );
  }

  void _handleVote(
    BuildContext context,
    Player votedPlayer,
    Player currentPlayer,
    bool hasVoted,
    bool hasVotedForThisPlayer,
  ) {
    final cubit = context.read<GameCubit>();
    final state = cubit.state;
    if (state is! GameLoaded) return;

    if (gameMode == 'local') {
      _showVoterSelectionDialog(context, votedPlayer.id);
    } else {
      // Check if trying to vote for self
      if (votedPlayer.userId == currentUserId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                const Text('❌ You cannot vote for yourself!'),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      // Check if already voted for someone else
      if (hasVoted && !hasVotedForThisPlayer) {
        _showChangeVoteDialog(
          context,
          cubit,
          state,
          currentPlayer,
          votedPlayer,
        );
      } else {
        // First time voting
        cubit.sendVote(
          roundId: round.id,
          voterId: currentPlayer.id,
          votedPlayerId: votedPlayer.id,
        );
      }
    }
  }

  void _showChangeVoteDialog(
    BuildContext context,
    GameCubit cubit,
    GameLoaded state,
    Player currentPlayer,
    Player newPlayer,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Change Vote?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to change your vote to ${newPlayer.username}?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.sendVote(
                roundId: round.id,
                voterId: currentPlayer.id,
                votedPlayerId: newPlayer.id,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonPrimary,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showVoterSelectionDialog(BuildContext context, String votedPlayerId) {
    // Save GameCubit reference before opening dialog to avoid accessing deactivated widget
    final gameCubit = context.read<GameCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Who is voting?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: players.map((player) {
            final hasVoted = round.playerVotes.containsKey(player.id);
            // Prevent voting for self
            final isVotingForSelf = player.id == votedPlayerId;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
              title: Text(
                player.username,
                style: TextStyle(color: AppColors.textPrimary),
              ),
              subtitle: isVotingForSelf
                  ? Text(
                      'Cannot vote for self',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    )
                  : null,
              trailing: hasVoted
                  ? FaIcon(
                      FontAwesomeIcons.circleCheck,
                      color: AppColors.success,
                      size: 20,
                    )
                  : null,
              enabled: !hasVoted && !isVotingForSelf,
              onTap: hasVoted || isVotingForSelf
                  ? null
                  : () {
                      gameCubit.sendVote(
                        roundId: round.id,
                        voterId: player.id,
                        votedPlayerId: votedPlayerId,
                      );
                      Navigator.of(dialogContext).pop();
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSubmittedCard(BuildContext context, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.voteSelectedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success, width: 2),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          FaIcon(
            FontAwesomeIcons.circleCheck,
            color: AppColors.success,
            size: isTablet ? 28 : 20,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              'Vote submitted! Waiting for results...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingProgress(BuildContext context, bool isTablet) {
    final progress = round.playerVotes.length / round.playerIds.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votes (${round.playerVotes.length}/${round.playerIds.length})',
            style: TextStyle(
              color: AppColors.textPrimary,
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
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VotePlayerTile extends StatelessWidget {
  final Player player;
  final bool isVotedFor;
  final bool isTablet;
  final VoidCallback onVote;

  const _VotePlayerTile({
    required this.player,
    required this.isVotedFor,
    required this.isTablet,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: isVotedFor
              ? AppColors.voteSelectedBg
              : AppColors.voteUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isVotedFor ? AppColors.success : AppColors.cardBorder,
            width: isVotedFor ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 8 : 4,
          ),
          leading: CircleAvatar(
            radius: isTablet ? 24 : 20,
            backgroundColor: AppColors.primary,
            child: Text(
              player.username[0].toUpperCase(),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: isTablet ? 20 : 16,
              ),
            ),
          ),
          title: Text(
            player.username,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          trailing: isVotedFor
              ? FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.success,
                  size: isTablet ? 28 : 22,
                )
              : ElevatedButton(
                  onPressed: onVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.textPrimary,
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
    );
  }
}

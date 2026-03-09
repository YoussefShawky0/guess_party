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
        ? round.playerVotes.length >=
              players
                  .length // All players voted
        : round.playerVotes.containsKey(
            currentPlayer.id,
          ); // Current player voted

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
          ? 'Find the Impostor! Each player taps their own name, then picks who they suspect.'
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
    // Build vote count map: votedPlayerId -> count
    final voteCountMap = <String, int>{};
    for (final votedId in round.playerVotes.values) {
      if (votedId != null) {
        voteCountMap[votedId] = (voteCountMap[votedId] ?? 0) + 1;
      }
    }

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
            gameMode == 'local'
                ? 'Tap your name to vote ↓'
                : 'Choose a suspect:',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...players.map((player) {
            // In online mode: hide self from list
            if (gameMode == 'online' && player.userId == currentUserId) {
              return const SizedBox.shrink();
            }

            final voteCount = voteCountMap[player.id] ?? 0;

            if (gameMode == 'local') {
              // LOCAL MODE: each tile = the VOTER (not the target)
              // Vote button means: "I (this player) want to cast my vote"
              final hasThisPlayerVoted = round.playerVotes.containsKey(
                player.id,
              );
              return _VotePlayerTile(
                player: player,
                voteCount: voteCount,
                iVotedForThis: false,
                hasAlreadyVotedAsVoter: hasThisPlayerVoted,
                isTablet: isTablet,
                onVote: () => _showTargetSelectionDialog(context, player.id),
              );
            } else {
              // ONLINE MODE: each tile = the TARGET (unchanged)
              final myVotedId = round.playerVotes[currentPlayer.id];
              final iVotedForThis = myVotedId == player.id;
              return _VotePlayerTile(
                player: player,
                voteCount: voteCount,
                iVotedForThis: iVotedForThis,
                hasAlreadyVotedAsVoter: false,
                isTablet: isTablet,
                onVote: () => _handleOnlineVote(
                  context,
                  player,
                  currentPlayer,
                  hasVoted,
                  iVotedForThis,
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  void _handleOnlineVote(
    BuildContext context,
    Player votedPlayer,
    Player currentPlayer,
    bool hasVoted,
    bool iVotedForThis,
  ) {
    final cubit = context.read<GameCubit>();
    if (cubit.state is! GameLoaded) return;

    if (hasVoted && !iVotedForThis) {
      // Already voted for someone else → ask to change
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Change Vote?',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            'Change your vote to ${votedPlayer.username}?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                cubit.sendVote(
                  roundId: round.id,
                  voterId: currentPlayer.id,
                  votedPlayerId: votedPlayer.id,
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
    } else {
      cubit.sendVote(
        roundId: round.id,
        voterId: currentPlayer.id,
        votedPlayerId: votedPlayer.id,
      );
    }
  }

  // LOCAL MODE: voter presses their own tile, then picks who to vote for
  void _showTargetSelectionDialog(BuildContext context, String voterId) {
    final gameCubit = context.read<GameCubit>();
    final voter = players.firstWhere((p) => p.id == voterId);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return BlocBuilder<GameCubit, GameState>(
          bloc: gameCubit,
          builder: (_, state) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${voter.username}, who do you suspect?',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the player you think is the Impostor',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: players.map((player) {
                    final isVotingForSelf = player.id == voterId;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isVotingForSelf
                            ? AppColors.surfaceLight
                            : AppColors.primary,
                        child: Text(
                          player.username[0].toUpperCase(),
                          style: TextStyle(
                            color: isVotingForSelf
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      title: Text(
                        player.username,
                        style: TextStyle(
                          color: isVotingForSelf
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: isVotingForSelf
                          ? Text(
                              'Cannot vote for self',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      enabled: !isVotingForSelf,
                      onTap: isVotingForSelf
                          ? null
                          : () async {
                              await gameCubit.sendVote(
                                roundId: round.id,
                                voterId: voterId,
                                votedPlayerId: player.id,
                              );
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            );
          },
        );
      },
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
  final int voteCount;
  final bool iVotedForThis; // online mode: I voted for this player
  final bool
  hasAlreadyVotedAsVoter; // local mode: this player already cast their vote
  final bool isTablet;
  final VoidCallback onVote;

  const _VotePlayerTile({
    required this.player,
    required this.voteCount,
    required this.iVotedForThis,
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
          color: (iVotedForThis || hasAlreadyVotedAsVoter)
              ? AppColors.voteSelectedBg
              : AppColors.voteUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (iVotedForThis || hasAlreadyVotedAsVoter)
                ? AppColors.success
                : AppColors.cardBorder,
            width: (iVotedForThis || hasAlreadyVotedAsVoter) ? 2 : 1,
          ),
        ),
        child: ListTile(
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
                    color: AppColors.textPrimary,
                    fontSize: isTablet ? 20 : 16,
                  ),
                ),
              ),
              // Vote count badge
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
                      border: Border.all(color: AppColors.surface, width: 1.5),
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
              color: AppColors.textPrimary,
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
          trailing: (iVotedForThis || hasAlreadyVotedAsVoter)
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

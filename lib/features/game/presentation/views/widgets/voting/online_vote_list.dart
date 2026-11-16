import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/vote_player_tile.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/voting_list_card.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';

/// Online mode: each tile is the vote TARGET; the current player is hidden.
class OnlineVoteList extends StatelessWidget {
  final RoundInfo round;
  final List<Player> players;
  final Player currentPlayer;
  final String currentUserId;
  final bool hasVoted;
  final bool isTablet;

  const OnlineVoteList({
    super.key,
    required this.round,
    required this.players,
    required this.currentPlayer,
    required this.currentUserId,
    required this.hasVoted,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return VotingListCard(
      title: context.l10n.chooseSuspect,
      isTablet: isTablet,
      children: [
        ...players.map((player) {
          // In online mode: hide self from list
          if (player.userId == currentUserId) {
            return const SizedBox.shrink();
          }

          final myVotedId = round.playerVotes[currentPlayer.id];
          final iVotedForThis = myVotedId == player.id;
          return VotePlayerTile(
            player: player,
            voteCount: 0,
            iVotedForThis: iVotedForThis,
            hasAlreadyVotedAsVoter: false,
            isTablet: isTablet,
            onVote: () => _handleOnlineVote(context, player, iVotedForThis),
          );
        }),
      ],
    );
  }

  void _handleOnlineVote(
    BuildContext context,
    Player votedPlayer,
    bool iVotedForThis,
  ) {
    if (votedPlayer.id == currentPlayer.id) {
      ErrorSnackBar.show(context, context.l10n.cannotVoteSelf);
      return;
    }

    final cubit = context.read<GameCubit>();
    if (cubit.state is! GameLoaded) return;

    if (hasVoted && !iVotedForThis) {
      // Already voted for someone else → ask to change
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.of(context).surface,
          title: Text(
            context.l10n.changeVote,
            style: TextStyle(color: AppColors.of(context).textPrimary),
          ),
          content: Text(
            context.l10n.changeVoteTo(votedPlayer.username),
            style: TextStyle(color: AppColors.of(context).textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: AppColors.of(context).textMuted),
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
              child: Text(context.l10n.confirm),
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
}

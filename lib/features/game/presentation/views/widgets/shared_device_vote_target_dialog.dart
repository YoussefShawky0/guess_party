import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';

/// Shared-Device mode: the voter picks who to vote for. Players and round are
/// read live from [GameCubit] so the list follows state updates.
void showSharedDeviceVoteTargetDialog(
  BuildContext context, {
  required String voterId,
}) {
  final gameCubit = context.read<GameCubit>();
  final currentState = gameCubit.state;
  if (currentState is! GameLoaded) return;
  Player? voter;
  for (final player in currentState.gameState.players) {
    if (player.id == voterId) {
      voter = player;
      break;
    }
  }
  if (voter == null) return;
  final resolvedVoter = voter;
  final theme = AppColors.of(context);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocBuilder<GameCubit, GameState>(
        bloc: gameCubit,
        builder: (_, state) {
          final players = state is GameLoaded
              ? state.gameState.players
              : currentState.gameState.players;
          final round = state is GameLoaded
              ? state.gameState.currentRound
              : currentState.gameState.currentRound;

          return AlertDialog(
            backgroundColor: theme.surface,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.whoDoYouSuspect(resolvedVoter.username),
                  style: TextStyle(color: theme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.voteForPlayerPrompt,
                  style: TextStyle(
                    color: theme.textSecondary,
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
                          ? theme.surfaceLight
                          : AppColors.primary,
                      child: Text(
                        player.username[0].toUpperCase(),
                        style: TextStyle(
                          color: isVotingForSelf
                              ? theme.textMuted
                              : theme.textPrimary,
                        ),
                      ),
                    ),
                    title: Text(
                      player.username,
                      style: TextStyle(
                        color: isVotingForSelf
                            ? theme.textMuted
                            : theme.textPrimary,
                      ),
                    ),
                    subtitle: isVotingForSelf
                        ? Text(
                            context.l10n.cannotVoteForSelf,
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          )
                        : null,
                    onTap: () async {
                      if (isVotingForSelf) {
                        if (!context.mounted) return;
                        ErrorSnackBar.show(
                          context,
                          context.l10n.cannotVoteSelf,
                        );
                        return;
                      }

                      Navigator.of(dialogContext).pop();
                      gameCubit.sendVote(
                        roundId: round.id,
                        voterId: voterId,
                        votedPlayerId: player.id,
                      );
                    },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(color: theme.textMuted),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

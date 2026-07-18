import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/shared/widgets/chat_widget.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'character_card.dart';
import 'results_phase_content.dart';
import 'round_header_widget.dart';
import 'voting_phase_content.dart';

class OnlineGameContent extends StatelessWidget {
  final GameLoaded state;
  final Player? currentPlayer;
  final bool isFinalizingVoting;
  final VoidCallback onPhaseTimeUp;
  final VoidCallback onSkipHints;
  final VoidCallback onSkipVoting;
  final VoidCallback onShowResults;
  final VoidCallback onNextRound;
  final VoidCallback onGameEnd;

  const OnlineGameContent({
    super.key,
    required this.state,
    required this.currentPlayer,
    required this.isFinalizingVoting,
    required this.onPhaseTimeUp,
    required this.onSkipHints,
    required this.onSkipVoting,
    required this.onShowResults,
    required this.onNextRound,
    required this.onGameEnd,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final players = gameState.players;
    if (players.isEmpty) {
      return Center(
        child: Text(
          context.l10n.waitingForPlayers,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    final currentPlayerId = currentPlayer?.id;
    final identityUnresolved =
        currentPlayerId == null || currentPlayerId.isEmpty;
    final isImposter = !identityUnresolved && round.isImposter(currentPlayerId);
    final isHost = currentPlayer?.isHost == true;
    final isTablet = MediaQuery.of(context).size.width > 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundHeaderWidget(
            round: round,
            totalRounds: gameState.totalRounds,
            roundDuration: gameState.roundDuration,
            onTimeUp: onPhaseTimeUp,
          ),
          const SizedBox(height: 16),
          if (identityUnresolved)
            const OnlineRoleSyncCard()
          else
            CharacterCard(
              character: round.character,
              isImposter: isImposter,
              gameMode: GameConstants.gameModeOnline,
            ),
          const SizedBox(height: 16),
          OnlineHostControls(
            phase: round.phase,
            isHost: isHost,
            onSkipHints: onSkipHints,
            onSkipVoting: onSkipVoting,
          ),
          if (isHost &&
              (round.phase == GamePhase.hints ||
                  round.phase == GamePhase.voting))
            const SizedBox(height: 16),
          if (round.phase == GamePhase.hints)
            ChatWidget(
              roomId: gameState.roomId,
              roundId: round.id,
              currentPlayerId: currentPlayerId ?? gameState.currentPlayerId,
            ),
          if (round.phase == GamePhase.voting)
            VotingPhaseContent(
              round: round,
              players: players,
              gameMode: GameConstants.gameModeOnline,
              currentUserId: gameState.currentPlayerId,
              isHost: isHost,
              isFinalizingVoting: isFinalizingVoting,
              onShowResults: onShowResults,
            ),
          if (round.phase == GamePhase.results)
            ResultsPhaseContent(
              roundInfo: round,
              players: players,
              playerScores: gameState.playerScores,
              voteCounts: round.voteCounts,
              onNextRound: onNextRound,
              onGameEnd: onGameEnd,
              isHost: isHost,
              isLastRound: gameState.isLastRound,
              totalRounds: gameState.totalRounds,
            ),
        ],
      ),
    );
  }
}

class OnlineRoleSyncCard extends StatelessWidget {
  const OnlineRoleSyncCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1.5),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.syncingRole,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class OnlineHostControls extends StatelessWidget {
  final GamePhase phase;
  final bool isHost;
  final VoidCallback onSkipHints;
  final VoidCallback onSkipVoting;

  const OnlineHostControls({
    super.key,
    required this.phase,
    required this.isHost,
    required this.onSkipHints,
    required this.onSkipVoting,
  });

  @override
  Widget build(BuildContext context) {
    if (!isHost || (phase != GamePhase.hints && phase != GamePhase.voting)) {
      return const SizedBox.shrink();
    }

    final isHints = phase == GamePhase.hints;
    return ElevatedButton.icon(
      key: const Key('online-host-skip-control'),
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              isHints ? context.l10n.skipHints : context.l10n.skipVoting,
            ),
            content: Text(
              isHints
                  ? context.l10n.skipHintsConfirmation
                  : context.l10n.skipVotingConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.skip),
              ),
            ],
          ),
        );
        if (!context.mounted || confirmed != true) return;
        if (isHints) {
          onSkipHints();
        } else {
          onSkipVoting();
        }
      },
      icon: const Icon(Icons.skip_next),
      label: Text(
        isHints ? context.l10n.skipToVoting : context.l10n.skipToResults,
      ),
    );
  }
}

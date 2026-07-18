import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/hints_phase_content.dart';
import 'package:guess_party/features/game/presentation/views/widgets/results_phase_content.dart';
import 'package:guess_party/features/game/presentation/views/widgets/round_header_widget.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting_phase_content.dart';
import 'package:guess_party/l10n/l10n.dart';

class LocalModeGameContent extends StatelessWidget {
  final GameLoaded state;
  final VoidCallback onTimeUp;
  final VoidCallback onShowResults;
  final VoidCallback onSkipToVoting;
  final VoidCallback onSkipToResults;
  final VoidCallback onNextRound;
  final VoidCallback onGameEnd;
  final bool isFinalizingVoting;

  const LocalModeGameContent({
    super.key,
    required this.state,
    required this.onTimeUp,
    required this.onShowResults,
    required this.onSkipToVoting,
    required this.onSkipToResults,
    required this.onNextRound,
    required this.onGameEnd,
    required this.isFinalizingVoting,
  });

  @override
  Widget build(BuildContext context) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final isTablet = MediaQuery.of(context).size.width > 600;
    final players = gameState.players;

    if (players.isEmpty) {
      return Center(
        child: Text(
          context.l10n.waitingForPlayers,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundHeaderWidget(
            round: round,
            totalRounds: gameState.totalRounds,
            roundDuration: gameState.roundDuration,
            onTimeUp: onTimeUp,
          ),
          const SizedBox(height: 16),
          const _LocalSharedCharacterCard(),
          const SizedBox(height: 16),
          if (round.phase == GamePhase.hints || round.phase == GamePhase.voting)
            _buildSkipButton(context, round.phase),
          if (round.phase == GamePhase.hints || round.phase == GamePhase.voting)
            const SizedBox(height: 16),
          if (round.phase == GamePhase.hints)
            HintsPhaseContent(
              round: round,
              players: players,
              gameMode: GameConstants.gameModeLocal,
              currentUserId: gameState.currentPlayerId,
            ),
          if (round.phase == GamePhase.voting)
            VotingPhaseContent(
              round: round,
              players: players,
              gameMode: GameConstants.gameModeLocal,
              currentUserId: gameState.currentPlayerId,
              isHost: true,
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
              isHost: true,
              isLastRound: gameState.isLastRound,
              totalRounds: gameState.totalRounds,
            ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, GamePhase phase) {
    final skipTarget = phase == GamePhase.hints
        ? context.l10n.votingPhase
        : context.l10n.resultsPhase;
    final skipLabel = phase == GamePhase.hints
        ? context.l10n.skipToVoting
        : context.l10n.skipToResults;

    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              phase == GamePhase.hints
                  ? context.l10n.skipHints
                  : context.l10n.skipVoting,
            ),
            content: Text(context.l10n.skipPhaseConfirmation(skipTarget)),
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

        if (confirmed != true || !context.mounted) {
          return;
        }

        if (phase == GamePhase.hints) {
          onSkipToVoting();
        } else {
          onSkipToResults();
        }
      },
      icon: const Icon(Icons.skip_next),
      label: Text(skipLabel),
    );
  }
}

class _LocalSharedCharacterCard extends StatelessWidget {
  const _LocalSharedCharacterCard();

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return Container(
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
            context.l10n.sharedGameScreen,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            context.l10n.sharedGameScreenHelp,
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

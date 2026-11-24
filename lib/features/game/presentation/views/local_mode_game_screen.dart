import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/game_loading_indicator.dart';
import 'package:guess_party/features/game/presentation/views/widgets/game_snackbars.dart';
import 'package:guess_party/features/game/presentation/views/widgets/leave_game_dialog.dart';
import 'package:guess_party/features/game/presentation/views/widgets/round_header_widget.dart';
import 'package:guess_party/features/game/presentation/views/widgets/shared_device_skip_phase_button.dart';
import 'package:guess_party/features/game/presentation/views/widgets/shared_device_vote_target_dialog.dart';
import 'package:guess_party/features/game/presentation/views/widgets/shared_device_phase_content.dart';
import 'package:guess_party/l10n/l10n.dart';

class LocalModeGameScreen extends StatefulWidget {
  final String roomId;
  final AuthSessionService session;

  const LocalModeGameScreen({
    super.key,
    required this.roomId,
    required this.session,
  });

  @override
  State<LocalModeGameScreen> createState() => _LocalModeGameScreenState();
}

class _LocalModeGameScreenState extends State<LocalModeGameScreen> {
  String? _isFinalizingVotingRoundId;
  bool _isStartingNextRound = false;

  void _handlePhaseTimeUp(GameLoaded state) {
    final round = state.gameState.currentRound;
    final phase = round.phase;

    if (phase == GamePhase.hints) {
      context.read<GameCubit>().progressPhase(round.id);
    } else if (phase == GamePhase.voting) {
      if (_isFinalizingVotingRoundId == round.id) return;
      _isFinalizingVotingRoundId = round.id;
      context.read<GameCubit>().finalizeVoting(round.id, 'timer').whenComplete(
        () {
          if (mounted) _isFinalizingVotingRoundId = null;
        },
      );
    }
  }

  /// [reason] must match what the server checks: 'all_votes' is rejected
  /// with VOTES_INCOMPLETE until every participant voted; a host skipping
  /// early must send 'host_skip' (same as Online Mode).
  void _finalizeVotingAndProgress(String roundId, {required String reason}) {
    if (_isFinalizingVotingRoundId == roundId) return;
    _isFinalizingVotingRoundId = roundId;
    context.read<GameCubit>().finalizeVoting(roundId, reason).whenComplete(() {
      if (mounted) _isFinalizingVotingRoundId = null;
    });
  }

  Future<void> _startNextRound(GameLoaded state) async {
    final round = state.gameState.currentRound;
    final nextRoundNumber = round.roundNumber + 1;
    final router = GoRouter.of(context);
    final gameCubit = context.read<GameCubit>();

    final created = await gameCubit.createNewRound(
      roomId: widget.roomId,
      roundNumber: nextRoundNumber,
    );
    if (!mounted || !created) return;
    router.go(AppRoutes.roomRoleReveal(widget.roomId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final router = GoRouter.of(context);
        final shouldExit = await showLeaveGameDialog(context);
        if (shouldExit && mounted) {
          router.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: AppBar(
          title: Text(context.l10n.sharedDeviceGame),
          backgroundColor: AppColors.of(context).surface,
          foregroundColor: AppColors.of(context).textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final router = GoRouter.of(context);
              final shouldExit = await showLeaveGameDialog(context);
              if (shouldExit && mounted) {
                router.go(AppRoutes.home);
              }
            },
          ),
        ),
        body: BlocConsumer<GameCubit, GameState>(
          listenWhen: (previous, current) =>
              current is GameError || current is GameEnded,
          listener: (context, state) {
            if (state is GameError) {
              if (!context.mounted) return;
              showGameErrorSnackBar(context, state.code);
            }
            if (state is GameEnded) {
              if (!context.mounted) return;
              context.go(
                AppRoutes.roomGameOver(widget.roomId),
                extra: {
                  'players': state.players,
                  'playerScores': state.playerScores,
                  'gameMode': GameConstants.gameModeLocal,
                },
              );
            }
          },
          builder: (context, state) {
            if (state is GameLoading) {
              return const GameLoadingIndicator();
            }

            if (state is GameError) {
              return ErrorScreen(
                message: localizedErrorMessage(context.l10n, state.code),
                onRetry: () {
                  context.read<GameCubit>().loadGameState(
                    roomId: widget.roomId,
                    currentPlayerId: widget.session.currentUserId ?? '',
                  );
                },
                onGoBack: () => context.go(AppRoutes.home),
              );
            }

            if (state is GameLoaded) {
              return _buildGameContent(state);
            }

            return Center(child: Text(context.l10n.preparing));
          },
        ),
      ),
    );
  }

  Widget _buildGameContent(GameLoaded state) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final players = gameState.players;
    final isTablet = MediaQuery.of(context).size.width > 600;

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
            onTimeUp: () => _handlePhaseTimeUp(state),
          ),
          const SizedBox(height: 16),
          SharedDeviceIntroCard(isTablet: isTablet),
          const SizedBox(height: 16),
          if (round.phase == GamePhase.hints ||
              round.phase == GamePhase.voting) ...[
            SharedDeviceSkipPhaseButton(
              phase: round.phase,
              onFinalizeVoting: (roundId) =>
                  _finalizeVotingAndProgress(roundId, reason: 'host_skip'),
            ),
            const SizedBox(height: 16),
          ],
          if (round.phase == GamePhase.hints)
            SharedDeviceHintsContent(isTablet: isTablet),
          if (round.phase == GamePhase.voting)
            SharedDeviceVotingContent(
              round: round,
              players: players,
              isTablet: isTablet,
              isFinalizing: _isFinalizingVotingRoundId == round.id,
              onSelectVoter: (playerId) =>
                  showSharedDeviceVoteTargetDialog(context, voterId: playerId),
              onShowResults: () =>
                  _finalizeVotingAndProgress(round.id, reason: 'all_votes'),
            ),
          if (round.phase == GamePhase.results)
            SharedDeviceResultsContent(
              state: state,
              isTablet: isTablet,
              isStartingNextRound: _isStartingNextRound,
              onFinishGame: () =>
                  context.read<GameCubit>().finishGame(widget.roomId),
              onStartNextRound: () async {
                setState(() => _isStartingNextRound = true);
                await _startNextRound(state);
                if (mounted) setState(() => _isStartingNextRound = false);
              },
            ),
        ],
      ),
    );
  }
}

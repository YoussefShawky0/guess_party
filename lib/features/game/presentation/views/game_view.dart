import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/feedback/game_feedback_listener.dart';
import 'package:guess_party/features/game/presentation/reconnect_notice_gate.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'widgets/online_game_content.dart';
import 'widgets/game_lifecycle_manager.dart';
import 'widgets/game_end_navigation_listener.dart';
import 'widgets/game_connection_feedback.dart';
import 'widgets/game_view_rules.dart';
import 'widgets/game_loading_indicator.dart';
import 'widgets/game_snackbars.dart';
import 'widgets/leave_game_dialog.dart';
import 'package:guess_party/l10n/l10n.dart';

class GameView extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;
  final AuthSessionService session;
  final RoomRepository roomRepository;
  final GameCubit Function() createGameCubit;

  const GameView({
    super.key,
    required this.roomId,
    required this.session,
    required this.roomRepository,
    required this.createGameCubit,
    this.preservedScores,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: session.userIdChanges,
      initialData: session.currentUserId,
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        if (currentUserId == null) {
          return Scaffold(
            backgroundColor: AppColors.of(context).background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (context) => createGameCubit()
            ..loadGameState(
              roomId: roomId,
              currentPlayerId: currentUserId,
              preservedScores: preservedScores,
            ),
          child: GameLifecycleManager(
            roomId: roomId,
            session: session,
            roomRepository: roomRepository,
            child: GameViewContent(
              roomId: roomId,
              roomRepository: roomRepository,
            ),
          ),
        );
      },
    );
  }
}

class GameViewContent extends StatefulWidget {
  final String roomId;
  final RoomRepository roomRepository;

  const GameViewContent({
    super.key,
    required this.roomId,
    required this.roomRepository,
  });

  @override
  State<GameViewContent> createState() => _GameViewContentState();
}

class _GameViewContentState extends State<GameViewContent> {
  final ReconnectNoticeGate _reconnectNoticeGate = ReconnectNoticeGate();
  String?
  _isAdvancingHintsRoundId; // Step 8: guard hints→voting duplicate transitions
  String?
  _isFinalizingVotingRoundId; // Track which round is currently finalizing

  bool _isCurrentRoomHost(GameStateEntity gameState) =>
      resolveCurrentRoomPlayer(gameState)?.isHost ?? false;

  bool _shouldAutoFinalizeVoting(GameLoaded previous, GameLoaded current) =>
      shouldAutoFinalizeVoting(
        previous: previous,
        current: current,
        finalizingRoundId: _isFinalizingVotingRoundId,
      );

  void _finalizeVotingAndProgress(
    BuildContext context,
    String roundId, {
    String reason = 'all_votes',
  }) {
    if (_isFinalizingVotingRoundId == roundId) {
      return;
    }

    _isFinalizingVotingRoundId = roundId;
    context.read<GameCubit>().finalizeVoting(roundId, reason).whenComplete(() {
      if (mounted) _isFinalizingVotingRoundId = null;
    });
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    final gameCubit = context.read<GameCubit>();
    final currentGameState = gameCubit.state;
    final isActivePhase =
        currentGameState is GameLoaded &&
        (currentGameState.gameState.currentRound.phase == GamePhase.hints ||
            currentGameState.gameState.currentRound.phase == GamePhase.voting);

    if (isActivePhase) {
      final shouldLeave = await showLeaveGameDialog(
        context,
        leaveForeground: AppColors.of(context).textPrimary,
      );
      if (!shouldLeave || !context.mounted) return;
    }

    // Get player info from game state
    final gameState = currentGameState;
    if (gameState is GameLoaded) {
      final currentPlayer = resolveCurrentRoomPlayer(gameState.gameState);
      if (currentPlayer == null) {
        if (context.mounted) {
          ErrorSnackBar.show(context, context.l10n.syncingPlayer);
        }
        return;
      }

      await widget.roomRepository.leaveRoom(
        playerId: currentPlayer.id,
        roomId: widget.roomId,
        isHost: currentPlayer.isHost,
      );
    }

    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameFeedbackListener(
      child: GameEndNavigationListener(
        roomId: widget.roomId,
        states: context.read<GameCubit>().stream,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _handleLeaveGame(context);
          },
          child: Scaffold(
            backgroundColor: AppColors.of(context).background,
            appBar: AppBar(
              title: Text(context.l10n.game),
              backgroundColor: AppColors.of(context).surface,
              foregroundColor: AppColors.of(context).textPrimary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleLeaveGame(context),
              ),
            ),
            body: BlocConsumer<GameCubit, GameState>(
              listenWhen: _shouldListen,
              listener: _onStateChanged,
              builder: _buildForState,
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldListen(GameState previous, GameState current) {
    if (previous is GameLoaded && current is GameLoaded) {
      final hasNewInlineMessage =
          current.nonFatalError != null &&
          current.nonFatalMessageId != previous.nonFatalMessageId;
      if (hasNewInlineMessage) return true;

      final reconnectStarted =
          !previous.isReconnecting && current.isReconnecting;
      if (reconnectStarted) {
        _reconnectNoticeGate.startCycle(DateTime.now());
        return false;
      }

      final reconnectEnded = previous.isReconnecting && !current.isReconnecting;
      if (reconnectEnded) return true;

      // Check for auto-finalize voting condition
      return _shouldAutoFinalizeVoting(previous, current);
    }
    return current is GameError ||
        (current is GameLoaded && current.nonFatalError != null);
  }

  void _onStateChanged(BuildContext context, GameState state) {
    // Auto-finalize voting: trigger score calculation and phase advance
    if (state is GameLoaded &&
        state.gameState.currentRound.phase == GamePhase.voting &&
        state.gameState.currentRound.allRequiredVotesSubmitted &&
        _isCurrentRoomHost(state.gameState) &&
        _isFinalizingVotingRoundId == null) {
      final round = state.gameState.currentRound;
      _isFinalizingVotingRoundId = round.id;
      context
          .read<GameCubit>()
          .finalizeVoting(round.id, 'all_votes')
          .whenComplete(() {
            if (mounted) _isFinalizingVotingRoundId = null;
          });
    }

    // Show error messages with better styling
    if (state is GameError) {
      if (!context.mounted) return;
      showGameErrorSnackBar(context, state.code);
    } else if (state is GameLoaded && state.nonFatalError != null) {
      if (!context.mounted) return;
      showGameWarningSnackBar(context, state.nonFatalError!);
    } else if (state is GameLoaded && !state.isReconnecting) {
      if (!context.mounted) return;
      if (!_reconnectNoticeGate.shouldShowBackOnline(DateTime.now())) {
        return;
      }
      showBackOnlineSnackBar(context);
    }
  }

  Widget _buildForState(BuildContext context, GameState state) {
    if (state is GameLoading) {
      return const GameLoadingIndicator();
    }

    if (state is GameError) {
      return ErrorScreen(
        message: localizedErrorMessage(context.l10n, state.code),
        onRetry: () {
          context.read<GameCubit>().loadGameState(
            roomId: widget.roomId,
            currentPlayerId: context.read<GameCubit>().currentPlayerId,
          );
        },
        onGoBack: () => context.go(AppRoutes.home),
      );
    }

    if (state is GameLoaded) {
      return GameConnectionFeedback(
        isReconnecting: state.isReconnecting,
        child: _buildGameContent(context, state),
      );
    }

    return Center(child: Text(context.l10n.preparing));
  }

  Widget _buildGameContent(BuildContext context, GameLoaded state) {
    final currentPlayer = resolveCurrentRoomPlayer(state.gameState);
    final round = state.gameState.currentRound;

    return OnlineGameContent(
      state: state,
      currentPlayer: currentPlayer,
      isFinalizingVoting: _isFinalizingVotingRoundId == round.id,
      onPhaseTimeUp: () => _handlePhaseTimeUp(context, state),
      onSkipHints: () {
        if (_isAdvancingHintsRoundId == round.id) return;
        _isAdvancingHintsRoundId = round.id;
        context.read<GameCubit>().progressPhase(round.id).whenComplete(() {
          if (mounted) _isAdvancingHintsRoundId = null;
        });
      },
      onSkipVoting: () =>
          _finalizeVotingAndProgress(context, round.id, reason: 'host_skip'),
      onShowResults: () => _finalizeVotingAndProgress(context, round.id),
      onNextRound: () => _startNextRound(context, state),
      onGameEnd: () => context.read<GameCubit>().finishGame(widget.roomId),
    );
  }

  void _startNextRound(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final nextRoundNumber = round.roundNumber + 1;

    context.read<GameCubit>().createNewRound(
      roomId: widget.roomId,
      roundNumber: nextRoundNumber,
    );
  }

  void _handlePhaseTimeUp(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final isHost = _isCurrentRoomHost(state.gameState);

    // Only host can advance phase
    if (!isHost) {
      return;
    }

    final phase = round.phase;

    if (phase == GamePhase.hints) {
      // Step 8: Guard duplicate hints→voting transition (mirrors voting guard)
      if (_isAdvancingHintsRoundId == round.id) {
        return;
      }
      _isAdvancingHintsRoundId = round.id;
      context
          .read<GameCubit>()
          .progressPhase(round.id)
          .then((_) {
            if (mounted) _isAdvancingHintsRoundId = null;
          })
          .catchError((_) {
            if (mounted) _isAdvancingHintsRoundId = null;
          });
    } else if (phase == GamePhase.voting) {
      // Guard: do not fire timer if voting is already being finalized
      // (by auto-transition or manual button)
      if (_isFinalizingVotingRoundId == round.id) {
        return;
      }

      _isFinalizingVotingRoundId = round.id;
      context.read<GameCubit>().finalizeVoting(round.id, 'timer').whenComplete(
        () {
          if (mounted) _isFinalizingVotingRoundId = null;
        },
      );
    }
    // Results phase is button-driven only — no auto-advance
  }
}

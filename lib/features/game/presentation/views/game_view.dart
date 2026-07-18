import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/reconnect_notice_gate.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'widgets/online_game_content.dart';
import 'widgets/game_lifecycle_manager.dart';
import 'widgets/game_end_navigation_listener.dart';
import 'widgets/game_connection_feedback.dart';
import 'package:guess_party/l10n/l10n.dart';

class GameView extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const GameView({super.key, required this.roomId, this.preservedScores});

  @override
  Widget build(BuildContext context) {
    final session = sl<AuthSessionService>();
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
          create: (context) => sl<GameCubit>()
            ..loadGameState(
              roomId: roomId,
              currentPlayerId: currentUserId,
              preservedScores: preservedScores,
            ),
          child: GameLifecycleManager(
            roomId: roomId,
            child: GameViewContent(roomId: roomId),
          ),
        );
      },
    );
  }
}

class GameViewContent extends StatefulWidget {
  final String roomId;

  const GameViewContent({super.key, required this.roomId});

  @override
  State<GameViewContent> createState() => _GameViewContentState();
}

class _GameViewContentState extends State<GameViewContent> {
  final ReconnectNoticeGate _reconnectNoticeGate = ReconnectNoticeGate();
  String?
  _isAdvancingHintsRoundId; // Step 8: guard hints→voting duplicate transitions
  String?
  _isFinalizingVotingRoundId; // Track which round is currently finalizing

  Player? _resolveCurrentRoomPlayer(GameStateEntity gameState) {
    final currentPlayerIdentifier = gameState.currentPlayerId;
    if (currentPlayerIdentifier.isEmpty) {
      return null;
    }

    for (final player in gameState.players) {
      if (player.id == currentPlayerIdentifier ||
          player.userId == currentPlayerIdentifier) {
        return player;
      }
    }

    return null;
  }

  bool _isCurrentRoomHost(GameStateEntity gameState) =>
      _resolveCurrentRoomPlayer(gameState)?.isHost ?? false;

  bool _shouldAutoFinalizeVoting(GameLoaded previous, GameLoaded current) {
    final prevRound = previous.gameState.currentRound;
    final currRound = current.gameState.currentRound;
    final currGameState = current.gameState;

    // Only for online mode
    if (currGameState.gameMode != GameConstants.gameModeOnline) {
      return false;
    }

    // Only if current phase is voting
    if (currRound.phase != GamePhase.voting) {
      return false;
    }

    // Only if current player is host
    if (!_isCurrentRoomHost(currGameState)) {
      return false;
    }

    // Only if not currently finalizing (manual button or timer race guard)
    if (_isFinalizingVotingRoundId == currRound.id) {
      return false;
    }

    final previousComplete = prevRound.allRequiredVotesSubmitted;
    final currentComplete = currRound.allRequiredVotesSubmitted;
    final onlinePlayerCount = current.gameState.players
        .where((p) => p.isOnline)
        .length;

    // Safety: need at least 2 online players for meaningful voting
    if (onlinePlayerCount < 2) return false;

    final votesJustCompleted = !previousComplete && currentComplete;

    if (!votesJustCompleted) {
      return false;
    }

    // All conditions met
    return true;
  }

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

  Future<bool> _showLeaveConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.of(context).surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.leaveGameTitle,
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
              ],
            ),
            content: Text(
              context.l10n.leaveGameMessage,
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  context.l10n.stay,
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.of(context).textPrimary,
                ),
                child: Text(context.l10n.leave),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    final gameCubit = context.read<GameCubit>();
    final currentGameState = gameCubit.state;
    final isActivePhase =
        currentGameState is GameLoaded &&
        (currentGameState.gameState.currentRound.phase == GamePhase.hints ||
            currentGameState.gameState.currentRound.phase == GamePhase.voting);

    if (isActivePhase) {
      final shouldLeave = await _showLeaveConfirmation(context);
      if (!shouldLeave || !context.mounted) return;
    }

    // Get player info from game state
    final gameState = currentGameState;
    if (gameState is GameLoaded) {
      final currentPlayer = _resolveCurrentRoomPlayer(gameState.gameState);
      if (currentPlayer == null) {
        if (context.mounted) {
          ErrorSnackBar.show(context, context.l10n.syncingPlayer);
        }
        return;
      }

      await sl<LeaveRoom>()(
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
    return GameEndNavigationListener(
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
            listenWhen: (previous, current) {
              if (previous is GameLoaded && current is GameLoaded) {
                final hasNewInlineMessage =
                    current.nonFatalMessage != null &&
                    current.nonFatalMessageId != previous.nonFatalMessageId;
                if (hasNewInlineMessage) return true;

                final reconnectStarted =
                    !previous.isReconnecting && current.isReconnecting;
                if (reconnectStarted) {
                  _reconnectNoticeGate.startCycle(DateTime.now());
                  return false;
                }

                final reconnectEnded =
                    previous.isReconnecting && !current.isReconnecting;
                if (reconnectEnded) return true;

                // Check for auto-finalize voting condition
                final shouldAutoFinalizeVoting = _shouldAutoFinalizeVoting(
                  previous,
                  current,
                );
                if (shouldAutoFinalizeVoting) return true;

                return false;
              }
              return current is GameError ||
                  (current is GameLoaded && current.nonFatalMessage != null);
            },
            listener: (context, state) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.of(context).textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.of(context).textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 4),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (state is GameLoaded && state.nonFatalMessage != null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.of(context).textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            state.nonFatalMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.of(context).textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.warning,
                    duration: const Duration(seconds: 3),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else if (state is GameLoaded && !state.isReconnecting) {
                if (!context.mounted) return;
                final now = DateTime.now();
                if (!_reconnectNoticeGate.shouldShowBackOnline(now)) {
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.wifi,
                          color: AppColors.of(context).textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.backOnlineSynced,
                            style: TextStyle(
                              color: AppColors.of(context).textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is GameLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.loadingGame,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (state is GameError) {
                return ErrorScreen(
                  message: state.message,
                  onRetry: () {
                    context.read<GameCubit>().loadGameState(
                      roomId: widget.roomId,
                      currentPlayerId: context
                          .read<GameCubit>()
                          .currentPlayerId,
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
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, GameLoaded state) {
    final currentPlayer = _resolveCurrentRoomPlayer(state.gameState);
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

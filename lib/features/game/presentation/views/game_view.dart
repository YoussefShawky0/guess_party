import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/character_card.dart';
import 'widgets/hints_phase_content.dart';
import 'widgets/results_phase_content.dart';
import 'widgets/round_header_widget.dart';
import 'widgets/voting_phase_content.dart';

class GameView extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const GameView({super.key, required this.roomId, this.preservedScores});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

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
  }
}

class GameLifecycleManager extends StatefulWidget {
  final String roomId;
  final Widget child;

  const GameLifecycleManager({
    super.key,
    required this.roomId,
    required this.child,
  });

  @override
  State<GameLifecycleManager> createState() => _GameLifecycleManagerState();
}

class _GameLifecycleManagerState extends State<GameLifecycleManager>
    with WidgetsBindingObserver {
  static const _heartbeatInterval = Duration(seconds: 25);
  Timer? _heartbeatTimer;

  Future<void> _setCurrentUserOnlineStatus(bool isOnline) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('players')
          .update({
            'is_online': isOnline,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('room_id', widget.roomId)
          .eq('user_id', userId);
    } catch (_) {
      // Best-effort heartbeat/status update.
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _setCurrentUserOnlineStatus(true);
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setCurrentUserOnlineStatus(true);
    _startHeartbeat();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeartbeat();
    _setCurrentUserOnlineStatus(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setCurrentUserOnlineStatus(true);
        _startHeartbeat();

        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'lifecycle',
            message: 'game resumed: refreshing state',
            level: SentryLevel.info,
            data: {'roomId': widget.roomId},
          ),
        );

        context.read<GameCubit>().refreshGameStateOnResume(
          roomId: widget.roomId,
        );
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _setCurrentUserOnlineStatus(false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class GameViewContent extends StatelessWidget {
  final String roomId;

  const GameViewContent({super.key, required this.roomId});

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
                  'Leave Game?',
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to leave? Other players will be notified and the game may end.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.of(context).textPrimary,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    final gameCubit = context.read<GameCubit>();

    final shouldLeave = await _showLeaveConfirmation(context);
    if (!shouldLeave || !context.mounted) return;

    final currentUserId = gameCubit.currentPlayerId;

    // Get player info from game state
    final gameState = gameCubit.state;
    if (gameState is GameLoaded) {
      final players = gameState.gameState.players;
      final currentPlayer = players.firstWhere(
        (p) => p.userId == currentUserId,
        orElse: () => players.first,
      );
      final isHost = currentPlayer.isHost;

      // Call leave-room use case directly (avoids creating a stale RoomCubit instance)
      await sl<LeaveRoom>()(
        playerId: currentPlayer.id,
        roomId: roomId,
        isHost: isHost,
      );
    }

    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleLeaveGame(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: AppBar(
          title: const Text('Game'),
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
              return previous.isReconnecting != current.isReconnecting;
            }
            return current is GameError || current is GameEnded;
          },
          listener: (context, state) {
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
            } else if (state is GameLoaded && !state.isReconnecting) {
              if (!context.mounted) return;
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
                          'Back online. Game synced.',
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
            } else if (state is GameEnded) {
              if (!context.mounted) return;
              context.go(
                AppRoutes.roomGameOver(roomId),
                extra: {
                  'players': state.players,
                  'playerScores': state.playerScores,
                },
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
                      'Loading game...',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is GameError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'An error occurred',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<GameCubit>().loadGameState(
                          roomId: roomId,
                          currentPlayerId: context
                              .read<GameCubit>()
                              .currentPlayerId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: AppColors.of(context).textPrimary,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.home),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              );
            }

            if (state is GameLoaded) {
              return Stack(
                children: [
                  _buildGameContent(context, state),
                  if (state.isReconnecting)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.of(context).textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Reconnecting to game...',
                                style: TextStyle(
                                  color: AppColors.of(context).textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }

            return const Center(child: Text('Preparing...'));
          },
        ),
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, GameLoaded state) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final currentUserId = state.gameState.currentPlayerId;
    final isImposter = round.isImposter(currentUserId);
    final isTablet = MediaQuery.of(context).size.width > 600;

    // حساب الـ host
    final currentPlayer = gameState.players.firstWhere(
      (p) => p.userId == currentUserId,
      orElse: () => gameState.players.first,
    );
    final isHost = currentPlayer.isHost;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundHeaderWidget(
            round: round,
            totalRounds: gameState.totalRounds,
            roundDuration: gameState.roundDuration,
            onTimeUp: () => _handlePhaseTimeUp(context, state),
          ),
          const SizedBox(height: 16),

          // Character Card Widget
          CharacterCard(
            character: round.character,
            isImposter: isImposter,
            gameMode: state.gameState.gameMode,
          ),
          const SizedBox(height: 16),

          // Phase-specific content
          if (round.phase == GamePhase.hints)
            HintsPhaseContent(
              round: round,
              players: state.gameState.players,
              gameMode: state.gameState.gameMode,
              currentUserId: currentUserId,
            ),
          if (round.phase == GamePhase.voting)
            VotingPhaseContent(
              round: round,
              players: state.gameState.players,
              gameMode: state.gameState.gameMode,
              currentUserId: currentUserId,
              isHost: isHost,
              onShowResults: () {
                // Await scoring completion before advancing phase
                context.read<GameCubit>().calculateRoundScores(round.id).then((
                  _,
                ) {
                  if (context.mounted) {
                    context.read<GameCubit>().progressPhase(round.id);
                  }
                });
              },
            ),
          if (round.phase == GamePhase.results)
            _buildResultsPhase(context, state),
        ],
      ),
    );
  }

  Widget _buildResultsPhase(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;
    final isLastRound = state.gameState.isLastRound;

    // Count votes
    final voteCounts = round.voteCounts;

    final currentUserId = state.gameState.currentPlayerId;
    final currentPlayer = players.firstWhere(
      (p) => p.userId == currentUserId,
      orElse: () => players.first,
    );
    final isHost = currentPlayer.isHost;

    return ResultsPhaseContent(
      roundInfo: round,
      players: players,
      playerScores: state.gameState.playerScores,
      voteCounts: voteCounts,
      onNextRound: () {
        final nextRoundNumber = round.roundNumber + 1;
        final gameMode = state.gameState.gameMode;
        // Capture scores BEFORE creating new round (in-memory accumulation)
        final currentScores = Map<String, int>.from(
          state.gameState.playerScores,
        );

        // Create new round
        context.read<GameCubit>().createNewRound(
          roomId: roomId,
          roundNumber: nextRoundNumber,
        );

        // In local mode, navigate to role reveal screen after a short delay
        // to allow the new round to be created.
        // Pass scores via extra so the new cubit instance can restore them.
        if (gameMode == GameConstants.gameModeLocal) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (context.mounted) {
              context.go(
                AppRoutes.roomRoleReveal(roomId),
                extra: {'playerScores': currentScores},
              );
            }
          });
        }
      },
      onGameEnd: () {
        context.read<GameCubit>().finishGame(roomId);
      },
      isHost: isHost,
      isLastRound: isLastRound,
      totalRounds: state.gameState.totalRounds,
    );
  }

  void _handlePhaseTimeUp(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final currentUserId = state.gameState.currentPlayerId;
    final hostUserId = state.gameState.players
        .firstWhere((p) => p.isHost)
        .userId;
    final isHost = currentUserId == hostUserId;

    // Only host can advance phase
    if (!isHost) {
      return;
    }

    final phase = round.phase;

    if (phase == GamePhase.hints) {
      context.read<GameCubit>().progressPhase(round.id);
    } else if (phase == GamePhase.voting) {
      // Calculate scores first, then advance phase
      context.read<GameCubit>().calculateRoundScores(round.id).then((_) {
        if (context.mounted) {
          context.read<GameCubit>().progressPhase(round.id);
        }
      });
    }
    // Results phase is button-driven only — no auto-advance
  }
}

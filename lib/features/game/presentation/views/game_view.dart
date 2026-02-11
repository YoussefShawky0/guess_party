import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'widgets/character_card.dart';
import 'widgets/hints_phase_content.dart';
import 'widgets/phase_timer_widget.dart';
import 'widgets/results_phase_content.dart';
import 'widgets/voting_phase_content.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameView extends StatelessWidget {
  final String roomId;

  const GameView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return BlocProvider(
      create: (context) =>
          sl<GameCubit>()
            ..loadGameState(roomId: roomId, currentPlayerId: currentUserId),
      child: GameViewContent(roomId: roomId),
    );
  }
}

class GameViewContent extends StatelessWidget {
  final String roomId;

  const GameViewContent({super.key, required this.roomId});

  Future<bool> _showLeaveConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
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
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to leave? Other players will be notified and the game may end.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.textPrimary,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    final shouldLeave = await _showLeaveConfirmation(context);
    if (!shouldLeave) return;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Get player info from game state
    final gameState = context.read<GameCubit>().state;
    if (gameState is GameLoaded) {
      final players = gameState.gameState.players;
      final currentPlayer = players.firstWhere(
        (p) => p.userId == currentUserId,
        orElse: () => players.first,
      );
      final isHost = currentPlayer.isHost;

      // Leave room using RoomCubit
      await sl<RoomCubit>().leaveRoomSession(
        playerId: currentPlayer.id,
        roomId: roomId,
        isHost: isHost,
      );
    }

    if (context.mounted) {
      context.go('/home');
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Game'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleLeaveGame(context),
          ),
        ),
        body: BlocConsumer<GameCubit, GameState>(
          listener: (context, state) {
            // Show error messages with better styling
            if (state is GameError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.textPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
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
                      style: TextStyle(color: AppColors.textSecondary),
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        final currentUserId =
                            Supabase.instance.client.auth.currentUser?.id ?? '';
                        context.read<GameCubit>().loadGameState(
                          roomId: roomId,
                          currentPlayerId: currentUserId,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonPrimary,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              );
            }

            if (state is GameLoaded) {
              return _buildGameContent(context, state);
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isImposter = round.isImposter(currentUserId);
    final isTablet = MediaQuery.of(context).size.width > 600;

    // حساب المدة الأصلية للراوند
    final totalDuration = gameState.roundDuration;
    final totalMinutes = totalDuration ~/ 60;
    final totalSeconds = totalDuration % 60;
    final durationText = totalSeconds > 0
        ? '$totalMinutes:${totalSeconds.toString().padLeft(2, '0')} min'
        : '$totalMinutes min';

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round info - Improved Layout
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.characterCardBg, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.characterCardBorder,
                width: 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              child: Column(
                children: [
                  // Top Row: Round number (left) + Timer (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Round number & total
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Round ${round.roundNumber}',
                            style: TextStyle(
                              fontSize: isTablet ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'of ${gameState.totalRounds}',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      // Timer
                      PhaseTimerWidget(
                        phaseEndTime: round.phaseEndTime,
                        onTimeUp: () => _handlePhaseTimeUp(context, state),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  // Phase info
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 20 : 16,
                      vertical: isTablet ? 12 : 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getPhaseIcon(round.phase),
                          color: AppColors.primary,
                          size: isTablet ? 24 : 20,
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Text(
                          _getPhaseText(round.phase),
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            durationText,
                            style: TextStyle(
                              fontSize: isTablet ? 14 : 12,
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
    final voteCounts = <String, int>{};
    for (final votedPlayerId in round.playerVotes.values) {
      if (votedPlayerId != null) {
        voteCounts[votedPlayerId] = (voteCounts[votedPlayerId] ?? 0) + 1;
      }
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final currentPlayer = players.firstWhere(
      (p) => p.userId == currentUserId,
      orElse: () => players.first,
    );
    // في Local mode، أول player يعتبر host
    final isHost = currentPlayer.id == players.first.id;

    return ResultsPhaseContent(
      roundInfo: round,
      players: players,
      playerScores: state.gameState.playerScores,
      voteCounts: voteCounts,
      onNextRound: () {
        final nextRoundNumber = round.roundNumber + 1;
        final gameMode = state.gameState.gameMode;

        // Create new round
        context.read<GameCubit>().createNewRound(
          roomId: roomId,
          roundNumber: nextRoundNumber,
        );

        // In local mode, navigate to role reveal screen after a short delay
        // to allow the new round to be created
        if (gameMode == 'local') {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (context.mounted) {
              context.go('/room/$roomId/role-reveal');
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

  String _getPhaseText(GamePhase phase) {
    switch (phase) {
      case GamePhase.hints:
        return 'Hints Phase';
      case GamePhase.voting:
        return 'Voting Phase';
      case GamePhase.results:
        return 'Results';
    }
  }

  IconData _getPhaseIcon(GamePhase phase) {
    switch (phase) {
      case GamePhase.hints:
        return FontAwesomeIcons.lightbulb;
      case GamePhase.voting:
        return FontAwesomeIcons.checkToSlot;
      case GamePhase.results:
        return FontAwesomeIcons.trophy;
    }
  }

  void _handlePhaseTimeUp(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
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
      // Calculate scores first
      context.read<GameCubit>().calculateRoundScores(round.id);
      // Then progress to results phase after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          context.read<GameCubit>().progressPhase(round.id);
        }
      });
    } else if (phase == GamePhase.results) {
      // Check if this is the last round
      if (state.gameState.isLastRound) {
        context.read<GameCubit>().finishGame(state.gameState.roomId);
        // Navigate to results screen (to be implemented)
        context.go('/home');
      } else {
        context.read<GameCubit>().createNewRound(
          roomId: state.gameState.roomId,
          roundNumber: round.roundNumber + 1,
        );
      }
    }
  }
}

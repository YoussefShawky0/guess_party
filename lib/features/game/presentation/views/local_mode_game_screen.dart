import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/round_header_widget.dart';
import 'package:guess_party/features/game/presentation/views/widgets/shared_device_phase_content.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';

class LocalModeGameScreen extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const LocalModeGameScreen({
    super.key,
    required this.roomId,
    this.preservedScores,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = sl<AuthSessionService>().currentUserId ?? '';

    return BlocProvider(
      create: (context) => sl<GameCubit>()
        ..loadGameState(
          roomId: roomId,
          currentPlayerId: currentUserId,
          preservedScores: preservedScores,
        ),
      child: _LocalModeGameBody(roomId: roomId),
    );
  }
}

class _LocalModeGameBody extends StatefulWidget {
  final String roomId;

  const _LocalModeGameBody({required this.roomId});

  @override
  State<_LocalModeGameBody> createState() => _LocalModeGameBodyState();
}

class _LocalModeGameBodyState extends State<_LocalModeGameBody> {
  String? _isFinalizingVotingRoundId;
  bool _isStartingNextRound = false;

  Future<bool> _showLeaveConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
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
              'Are you sure you want to leave? The game will end.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

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

  void _finalizeVotingAndProgress(String roundId) {
    if (_isFinalizingVotingRoundId == roundId) return;
    _isFinalizingVotingRoundId = roundId;
    context.read<GameCubit>().finalizeVoting(roundId, 'all_votes').whenComplete(
      () {
        if (mounted) _isFinalizingVotingRoundId = null;
      },
    );
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
        final shouldExit = await _showLeaveConfirmation();
        if (shouldExit && mounted) {
          router.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: AppBar(
          title: const Text('Game'),
          backgroundColor: AppColors.of(context).surface,
          foregroundColor: AppColors.of(context).textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final router = GoRouter.of(context);
              final shouldExit = await _showLeaveConfirmation();
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
            }
            if (state is GameEnded) {
              if (!context.mounted) return;
              context.go(
                AppRoutes.roomGameOver(widget.roomId),
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
              return ErrorScreen(
                message: state.message,
                onRetry: () {
                  context.read<GameCubit>().loadGameState(
                    roomId: widget.roomId,
                    currentPlayerId:
                        sl<AuthSessionService>().currentUserId ?? '',
                  );
                },
                onGoBack: () => context.go(AppRoutes.home),
              );
            }

            if (state is GameLoaded) {
              return _buildGameContent(state);
            }

            return const Center(child: Text('Preparing...'));
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
          'Waiting for players...',
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
            _buildSkipButton(round.phase),
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
                  _showLocalTargetSelectionDialog(context, playerId),
              onShowResults: () => _finalizeVotingAndProgress(round.id),
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

  Widget _buildSkipButton(GamePhase phase) {
    final skipTarget = phase == GamePhase.hints ? 'voting' : 'results';
    final skipLabel = phase == GamePhase.hints
        ? 'Skip to Voting'
        : 'Skip to Results';

    return ElevatedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Skip ${phase.name}?'),
            content: Text('Are you sure you want to skip to $skipTarget?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Skip'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;

        final current = context.read<GameCubit>().state;
        if (current is! GameLoaded) return;
        if (phase == GamePhase.hints) {
          context.read<GameCubit>().progressPhase(
            current.gameState.currentRound.id,
          );
        } else {
          _finalizeVotingAndProgress(current.gameState.currentRound.id);
        }
      },
      icon: const Icon(Icons.skip_next),
      label: Text(skipLabel),
    );
  }

  void _showLocalTargetSelectionDialog(BuildContext context, String voterId) {
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
                    '${resolvedVoter.username}, who do you suspect?',
                    style: TextStyle(color: theme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the player you think is the Impostor',
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
                              'Cannot vote for self',
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
                            'You cannot vote for yourself',
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
                    'Cancel',
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
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/current_scores_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/imposter_reveal_card.dart';
import 'package:guess_party/features/game/presentation/views/widgets/round_header_widget.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting_results_card.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

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
                        Supabase.instance.client.auth.currentUser?.id ?? '',
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
          _buildLocalCharacterCard(isTablet),
          const SizedBox(height: 16),
          if (round.phase == GamePhase.hints || round.phase == GamePhase.voting)
            _buildSkipButton(round.phase),
          if (round.phase == GamePhase.hints || round.phase == GamePhase.voting)
            const SizedBox(height: 16),
          if (round.phase == GamePhase.hints) _buildHintsContent(isTablet),
          if (round.phase == GamePhase.voting)
            _buildVotingContent(state, isTablet),
          if (round.phase == GamePhase.results)
            _buildResultsContent(state, isTablet),
        ],
      ),
    );
  }

  Widget _buildLocalCharacterCard(bool isTablet) {
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
            'Shared game screen',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Text(
            'Continue the round on the shared device.',
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

  Widget _buildHintsContent(bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).hintCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.of(context).hintCardBorder,
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        children: [
          Icon(
            Icons.people,
            size: isTablet ? 64 : 48,
            color: AppColors.of(context).characterCardIcon,
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Text(
            'Discuss and give hints verbally!',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 20 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            'Talk about the character without revealing yourself. The timer will move to voting automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.of(context).textSecondary,
              fontSize: isTablet ? 16 : 14,
            ),
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

        if (phase == GamePhase.hints) {
          context.read<GameCubit>().progressPhase(
            context.read<GameCubit>().state is GameLoaded
                ? (context.read<GameCubit>().state as GameLoaded)
                      .gameState
                      .currentRound
                      .id
                : '',
          );
        } else {
          final state = context.read<GameCubit>().state;
          if (state is GameLoaded) {
            _finalizeVotingAndProgress(state.gameState.currentRound.id);
          }
        }
      },
      icon: const Icon(Icons.skip_next),
      label: Text(skipLabel),
    );
  }

  Widget _buildVotingContent(GameLoaded state, bool isTablet) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;

    final allVoted = round.allRequiredVotesSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Voting Phase',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Find the Impostor! Each player taps their own name, then picks who they suspect.',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _buildLocalVotingList(isTablet, players, round),
        SizedBox(height: isTablet ? 20 : 16),
        _buildVotingProgress(isTablet, players, round),
        if (allVoted) ...[
          SizedBox(height: isTablet ? 16 : 12),
          _buildShowResultsButton(isTablet, round.id),
        ],
      ],
    );
  }

  Widget _buildLocalVotingList(
    bool isTablet,
    List<Player> players,
    RoundInfo round,
  ) {
    final voteCountMap = round.voteCounts;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tap your name to vote ↓',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          ...players.map((player) {
            final voteCount = voteCountMap[player.id] ?? 0;
            final hasThisPlayerVoted = round.playerVotes.containsKey(player.id);

            return _LocalVotePlayerTile(
              player: player,
              voteCount: voteCount,
              hasAlreadyVotedAsVoter: hasThisPlayerVoted,
              isTablet: isTablet,
              onVote: () => _showLocalTargetSelectionDialog(context, player.id),
            );
          }),
        ],
      ),
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

  Widget _buildVotingProgress(
    bool isTablet,
    List<Player> players,
    RoundInfo round,
  ) {
    final progress = round.requiredVoteCount <= 0
        ? 0.0
        : (round.submittedVoteCount / round.requiredVoteCount)
              .clamp(0.0, 1.0)
              .toDouble();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.of(context).cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Votes (${round.submittedVoteCount}/${round.requiredVoteCount})',
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: isTablet ? 12 : 8,
              backgroundColor: AppColors.of(context).surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShowResultsButton(bool isTablet, String roundId) {
    return ElevatedButton.icon(
      onPressed: _isFinalizingVotingRoundId == roundId
          ? null
          : () => _finalizeVotingAndProgress(roundId),
      icon: const Icon(Icons.check_circle_outline),
      label: Text(
        _isFinalizingVotingRoundId == roundId
            ? 'Finalizing Results...'
            : 'Show Results Now →',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        foregroundColor: AppColors.of(context).textPrimary,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildResultsContent(GameLoaded state, bool isTablet) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;
    if (players.isEmpty) return const SizedBox.shrink();
    final imposterPlayerId = round.imposterPlayerId;
    if (imposterPlayerId == null || round.character == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final voteCounts = round.voteCounts;
    final isLastRound = state.gameState.isLastRound;

    Player? imposter;
    for (final player in players) {
      if (player.id == imposterPlayerId) {
        imposter = player;
        break;
      }
    }
    if (imposter == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maxVotes = voteCounts.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );
    final topEntries = maxVotes == 0
        ? const <MapEntry<String, int>>[]
        : voteCounts.entries
              .where((entry) => entry.value == maxVotes)
              .toList(growable: false);
    final mostVotedPlayerId = topEntries.length == 1
        ? topEntries.single.key
        : null;
    final imposterCaught = mostVotedPlayerId == imposterPlayerId;

    Player? mostVotedPlayer;
    if (mostVotedPlayerId != null) {
      for (final player in players) {
        if (player.id == mostVotedPlayerId) {
          mostVotedPlayer = player;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ImposterRevealCard(imposter: imposter, imposterCaught: imposterCaught),
        SizedBox(height: isTablet ? 24 : 16),
        VotingResultsCard(
          voteCounts: voteCounts,
          players: players,
          imposterPlayerId: imposterPlayerId,
          mostVotedPlayer: mostVotedPlayer,
          maxVotes: maxVotes,
        ),
        SizedBox(height: isTablet ? 24 : 16),
        CurrentScoresCard(
          players: players,
          playerScores: state.gameState.playerScores,
          imposterPlayerId: imposterPlayerId,
        ),
        SizedBox(height: isTablet ? 32 : 24),
        if (isLastRound)
          ElevatedButton.icon(
            onPressed: () =>
                context.read<GameCubit>().finishGame(widget.roomId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldMedal,
              foregroundColor: AppColors.scoreBadgeText,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.leaderboard_rounded, size: isTablet ? 24 : 20),
            label: Text(
              'View Final Leaderboard',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          ElevatedButton(
            onPressed: _isStartingNextRound
                ? null
                : () async {
                    setState(() => _isStartingNextRound = true);
                    await _startNextRound(state);
                    if (mounted) {
                      setState(() => _isStartingNextRound = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: AppColors.of(context).textPrimary,
              padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _isStartingNextRound ? 'Creating Round...' : 'Start Next Round',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}

class _LocalVotePlayerTile extends StatelessWidget {
  final Player player;
  final int voteCount;
  final bool hasAlreadyVotedAsVoter;
  final bool isTablet;
  final VoidCallback onVote;

  const _LocalVotePlayerTile({
    required this.player,
    required this.voteCount,
    required this.hasAlreadyVotedAsVoter,
    required this.isTablet,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 12 : 8),
      child: Container(
        decoration: BoxDecoration(
          color: hasAlreadyVotedAsVoter
              ? AppColors.voteSelectedBg
              : AppColors.of(context).voteUnselectedBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasAlreadyVotedAsVoter
                ? AppColors.success
                : AppColors.of(context).cardBorder,
            width: hasAlreadyVotedAsVoter ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isTablet ? 20 : 16,
            vertical: isTablet ? 8 : 4,
          ),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: isTablet ? 24 : 20,
                backgroundColor: AppColors.primary,
                child: Text(
                  player.username[0].toUpperCase(),
                  style: TextStyle(
                    color: AppColors.of(context).textPrimary,
                    fontSize: isTablet ? 20 : 16,
                  ),
                ),
              ),
              if (voteCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    width: isTablet ? 22 : 18,
                    height: isTablet ? 22 : 18,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.of(context).surface,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$voteCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 12 : 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            player.username,
            style: TextStyle(
              color: AppColors.of(context).textPrimary,
              fontSize: isTablet ? 18 : 16,
            ),
          ),
          subtitle: voteCount > 0
              ? Text(
                  voteCount == 1 ? '1 vote' : '$voteCount votes',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: isTablet ? 13 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                )
              : null,
          trailing: hasAlreadyVotedAsVoter
              ? FaIcon(
                  FontAwesomeIcons.circleCheck,
                  color: AppColors.success,
                  size: isTablet ? 28 : 22,
                )
              : ElevatedButton(
                  onPressed: onVote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    foregroundColor: AppColors.of(context).textPrimary,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Vote',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

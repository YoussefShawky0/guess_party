import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'widgets/phase_timer_widget.dart';
import 'widgets/results_phase_content.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
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
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading game...'),
                ],
              ),
            );
          }

          if (state is GameError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'An error occurred',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }

  Widget _buildGameContent(BuildContext context, GameLoaded state) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isImposter = round.isImposter(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Round info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Round ${round.roundNumber}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getPhaseText(round.phase),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  PhaseTimerWidget(
                    phaseEndTime: round.phaseEndTime,
                    onTimeUp: () => _handlePhaseTimeUp(context, state),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Character info (hidden for imposter)
          if (!isImposter)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.person, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Character',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      round.character.name,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${round.character.emoji} - ${round.character.category}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.warning, size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      '⚠️ You are the Impostor!',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You don\'t know the character! Try to guess from the hints',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Phase-specific content
          if (round.phase == GamePhase.hints)
            _buildHintsPhase(context, state, currentUserId),
          if (round.phase == GamePhase.voting)
            _buildVotingPhase(context, state, currentUserId),
          if (round.phase == GamePhase.results)
            _buildResultsPhase(context, state),
        ],
      ),
    );
  }

  Widget _buildHintsPhase(
    BuildContext context,
    GameLoaded state,
    String currentUserId,
  ) {
    final round = state.gameState.currentRound;
    final gameMode = state.gameState.gameMode;
    final hasSubmittedHint = round.playerHints.containsKey(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hints Phase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        // For local mode, no hint input - just show instructions
        if (gameMode == 'local')
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.people, size: 48, color: Colors.blue),
                  const SizedBox(height: 12),
                  Text(
                    'Discuss and give hints verbally!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Talk about the character without revealing yourself. The timer will move to voting automatically.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Online mode - show hint input
          const Text(
            'Give a hint about the character without revealing yourself!',
          ),
          const SizedBox(height: 16),
          if (!hasSubmittedHint)
            _buildHintInput(context)
          else
            Card(
              color: Colors.green.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Your hint has been submitted! Wait for other players...',
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _buildHintsList(context, state, round),
        ],
      ],
    );
  }

  Widget _buildHintInput(BuildContext context) {
    final controller = TextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Write your hint here',
                border: OutlineInputBorder(),
                hintText: 'مثال: يستخدم في المطبخ',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                final hint = controller.text.trim();
                if (hint.isNotEmpty) {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id ?? '';
                  final cubit = context.read<GameCubit>();
                  final state = cubit.state;
                  if (state is GameLoaded) {
                    // Find the actual player_id from players list using user_id
                    final currentPlayer = state.gameState.players.firstWhere(
                      (p) => p.userId == currentUserId,
                      orElse: () => state.gameState.players.first,
                    );

                    cubit.sendHint(
                      roundId: state.gameState.currentRound.id,
                      playerId: currentPlayer.id, // Use player.id not user.id
                      hint: hint,
                    );
                  }
                }
              },
              icon: const Icon(Icons.send),
              label: const Text('Submit Hint'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintsList(BuildContext context, GameLoaded state, RoundInfo round) {
    if (round.playerHints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No hints yet...'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hints Submitted (${round.playerHints.length}/${round.playerIds.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...round.playerHints.entries.map((entry) {
              final playerId = entry.key;
              final hint = entry.value;
              
              // Find player by ID to get username
              final player = state.gameState.players.firstWhere(
                (p) => p.id == playerId,
                orElse: () => state.gameState.players.first,
              );
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${player.username}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(text: hint ?? 'Hidden hint'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildVotingPhase(
    BuildContext context,
    GameLoaded state,
    String currentUserId,
  ) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;
    final gameMode = state.gameState.gameMode;
    final hasVoted = round.playerVotes.containsKey(currentUserId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Voting Phase', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          gameMode == 'local'
              ? 'Pass the phone - each player votes for who they think is the Impostor!'
              : 'Vote for who you think is the Impostor!',
        ),
        const SizedBox(height: 16),
        // For local mode, always show voting list (one device, multiple players)
        // For online mode, show only if current user hasn't voted
        if (gameMode == 'local' || !hasVoted)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameMode == 'local'
                        ? 'Select player to vote:'
                        : 'Choose player:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...players.map((player) {
                    // In local mode, show all players. In online mode, hide current user
                    if (gameMode == 'online' && player.id == currentUserId) {
                      return const SizedBox.shrink();
                    }

                    // Check if current user already voted for this player
                    final currentPlayer = players.firstWhere(
                      (p) => p.userId == currentUserId,
                      orElse: () => players.first,
                    );
                    final hasVotedForThisPlayer = gameMode == 'online' &&
                        round.playerVotes[currentPlayer.id] == player.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(player.username[0].toUpperCase()),
                        ),
                        title: Text(player.username),
                        trailing: hasVotedForThisPlayer
                            ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 32,
                              )
                            : ElevatedButton(
                                onPressed: () {
                                  final cubit = context.read<GameCubit>();
                                  final state = cubit.state;
                                  if (state is GameLoaded) {
                                    if (gameMode == 'local') {
                                      _showVoterSelectionDialog(
                                        context,
                                        player.id,
                                        state,
                                      );
                                    } else {
                                      // Check if trying to vote for self
                                      if (player.userId == currentUserId) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '❌ You cannot vote for yourself!',
                                            ),
                                            backgroundColor: Colors.red,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      // Check if already voted for someone else
                                      if (hasVoted && !hasVotedForThisPlayer) {
                                        _showChangeVoteDialog(
                                          context,
                                          cubit,
                                          state,
                                          currentPlayer.id,
                                          player,
                                        );
                                      } else {
                                        // First time voting
                                        cubit.sendVote(
                                          roundId: round.id,
                                          voterId: currentPlayer.id,
                                          votedPlayerId: player.id,
                                        );
                                      }
                                    }
                                  }
                                },
                                child: const Text('Vote'),
                              ),
                        tileColor: hasVotedForThisPlayer
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: hasVotedForThisPlayer
                              ? const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          )
        else
          Card(
            color: Colors.green.shade50,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Vote submitted! Waiting for results...'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الأصوات (${round.playerVotes.length}/${round.playerIds.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: round.playerVotes.length / round.playerIds.length,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsPhase(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;
    
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
        context.read<GameCubit>().createNewRound(
          roomId: roomId,
          roundNumber: nextRoundNumber,
        );
      },
      isHost: isHost,
    );
  }

  String _getPhaseText(GamePhase phase) {
    switch (phase) {
      case GamePhase.hints:
        return 'Hints Phase 💡';
      case GamePhase.voting:
        return 'Voting Phase 🗳️';
      case GamePhase.results:
        return 'Results 🏆';
    }
  }

  void _showChangeVoteDialog(
    BuildContext context,
    GameCubit cubit,
    GameLoaded state,
    String voterId,
    dynamic newPlayer,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Vote?'),
        content: Text(
          'Are you sure you want to change your vote to ${newPlayer.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              cubit.sendVote(
                roundId: state.gameState.currentRound.id,
                voterId: voterId,
                votedPlayerId: newPlayer.id,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showVoterSelectionDialog(
    BuildContext context,
    String votedPlayerId,
    GameLoaded state,
  ) {
    final players = state.gameState.players;
    final round = state.gameState.currentRound;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Who is voting?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: players.map((player) {
            final hasVoted = round.playerVotes.containsKey(player.id);
            return ListTile(
              leading: CircleAvatar(child: Text(player.username[0])),
              title: Text(player.username),
              trailing: hasVoted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              enabled: !hasVoted,
              onTap: hasVoted
                  ? null
                  : () {
                      context.read<GameCubit>().sendVote(
                        roundId: round.id,
                        voterId: player.id,
                        votedPlayerId: votedPlayerId,
                      );
                      Navigator.of(dialogContext).pop();
                    },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _handlePhaseTimeUp(BuildContext context, GameLoaded state) {
    print('⏰ Phase time is up!');
    
    final round = state.gameState.currentRound;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final hostUserId = state.gameState.players
        .firstWhere((p) => p.isHost)
        .userId;
    final isHost = currentUserId == hostUserId;

    print('👤 Current user: $currentUserId');
    print('👑 Host user: $hostUserId');
    print('🎭 Is host: $isHost');
    print('📍 Current phase: ${round.phase}');

    // Only host can advance phase
    if (!isHost) {
      print('⏭️ Not host, skipping phase advance');
      return;
    }

    final phase = round.phase;

    if (phase == GamePhase.hints) {
      print('🔄 Moving from Hints → Voting');
      context.read<GameCubit>().progressPhase(round.id);
    } else if (phase == GamePhase.voting) {
      print('🔄 Moving from Voting → Results (calculating scores)');
      // Calculate scores first
      context.read<GameCubit>().calculateRoundScores(round.id);
      // Then progress to results phase after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
          print('🔄 Advancing to Results phase');
          context.read<GameCubit>().progressPhase(round.id);
        }
      });
    } else if (phase == GamePhase.results) {
      print('🔄 Results phase complete');
      // Check if this is the last round
      if (state.gameState.isLastRound) {
        print('🏁 Last round - ending game');
        context.read<GameCubit>().finishGame(state.gameState.roomId);
        // Navigate to results screen (to be implemented)
        context.go('/home');
      } else {
        print('➡️ Creating next round: ${round.roundNumber + 1}');
        context.read<GameCubit>().createNewRound(
          roomId: state.gameState.roomId,
          roundNumber: round.roundNumber + 1,
        );
      }
    }
  }
}

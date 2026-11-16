import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/local_vote_list.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/online_vote_list.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/voting_show_results_section.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/voting_status_cards.dart';
import 'package:guess_party/l10n/l10n.dart';

class VotingPhaseContent extends StatelessWidget {
  final RoundInfo round;
  final List<Player> players;
  final String gameMode;
  final String currentUserId;
  final bool isHost;
  final bool isFinalizingVoting;
  final VoidCallback? onShowResults;

  const VotingPhaseContent({
    super.key,
    required this.round,
    required this.players,
    required this.gameMode,
    required this.currentUserId,
    this.isHost = false,
    this.isFinalizingVoting = false,
    this.onShowResults,
  });

  bool get _isLocal => gameMode == GameConstants.gameModeLocal;

  Player? _resolveCurrentPlayer() {
    if (currentUserId.isEmpty) {
      return null;
    }

    for (final player in players) {
      if (player.userId == currentUserId) {
        return player;
      }
    }

    return null;
  }

  /// Local mode: ALL current players have voted.
  /// Online mode: the current player has voted.
  bool _hasVoted(Player? currentPlayer) => _isLocal
      ? players.every((p) => round.playerVotes.containsKey(p.id))
      : currentPlayer != null
      ? round.playerVotes.containsKey(currentPlayer.id)
      : false;

  /// Casting a vote / vote submitted / syncing-player section.
  Widget _buildVoteSection(
    bool isTablet,
    Player? currentPlayer,
    bool hasVoted,
  ) {
    if (!_isLocal && hasVoted) {
      return VoteSubmittedCard(isTablet: isTablet);
    }
    if (currentPlayer == null) {
      return VotingPlayerNotFoundCard(isTablet: isTablet);
    }
    if (_isLocal) {
      return LocalVoteList(round: round, players: players, isTablet: isTablet);
    }
    return OnlineVoteList(
      round: round,
      players: players,
      currentPlayer: currentPlayer,
      currentUserId: currentUserId,
      hasVoted: hasVoted,
      isTablet: isTablet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    // Safely resolve current player (returns null if not found)
    final currentPlayer = _resolveCurrentPlayer();
    final hasVoted = _hasVoted(currentPlayer);
    final allVoted = round.allRequiredVotesSubmitted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.votingPhase,
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          _isLocal
              ? context.l10n.localVotingHelp
              : context.l10n.onlineVotingHelp,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: isTablet ? 16 : 14,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        _buildVoteSection(isTablet, currentPlayer, hasVoted),
        SizedBox(height: isTablet ? 20 : 16),
        VotingProgressCard(round: round, isTablet: isTablet),
        if (allVoted) ...[
          SizedBox(height: isTablet ? 16 : 12),
          VotingShowResultsSection(
            isHost: isHost,
            isFinalizingVoting: isFinalizingVoting,
            onShowResults: onShowResults,
            isTablet: isTablet,
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/local_voter_target_dialog.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/vote_player_tile.dart';
import 'package:guess_party/features/game/presentation/views/widgets/voting/voting_list_card.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Shared-Device mode: each tile is the VOTER ("I want to cast my vote").
class LocalVoteList extends StatelessWidget {
  final RoundInfo round;
  final List<Player> players;
  final bool isTablet;

  const LocalVoteList({
    super.key,
    required this.round,
    required this.players,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    // votedPlayerId -> count
    final voteCountMap = round.voteCounts;

    return VotingListCard(
      title: context.l10n.tapOwnNameToVote,
      isTablet: isTablet,
      children: [
        ...players.map((player) {
          final hasThisPlayerVoted = round.playerVotes.containsKey(player.id);
          return VotePlayerTile(
            player: player,
            voteCount: voteCountMap[player.id] ?? 0,
            iVotedForThis: false,
            hasAlreadyVotedAsVoter: hasThisPlayerVoted,
            isTablet: isTablet,
            onVote: () => showLocalVoterTargetDialog(
              context,
              players: players,
              roundId: round.id,
              voterId: player.id,
            ),
          );
        }),
      ],
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';

enum GamePhase { hints, voting, results }

class RoundInfo extends Equatable {
  static const Object _unset = Object();

  final String id;
  final String roomId;
  final String? imposterPlayerId;
  final Character? character;
  final int roundNumber;
  final GamePhase phase;
  final DateTime phaseEndTime;
  final bool imposterRevealed;
  final List<String> playerIds;
  final Map<String, String?> playerHints; // playerId -> hint
  final Map<String, String?> playerVotes; // voterId -> votedPlayerId
  final int submittedVoteCount;
  final int requiredVoteCount;

  const RoundInfo({
    required this.id,
    required this.roomId,
    required this.imposterPlayerId,
    required this.character,
    required this.roundNumber,
    required this.phase,
    required this.phaseEndTime,
    required this.imposterRevealed,
    required this.playerIds,
    required this.playerHints,
    required this.playerVotes,
    this.submittedVoteCount = 0,
    this.requiredVoteCount = 0,
  });

  bool isImposter(String playerId) => playerId == imposterPlayerId;

  bool get hasVisibleImposter => imposterPlayerId != null;

  bool get hasVisibleCharacter => character != null;

  bool get allRequiredVotesSubmitted =>
      requiredVoteCount > 0 && submittedVoteCount >= requiredVoteCount;

  int get remainingSeconds {
    final now = DateTime.now().toUtc();
    final difference = phaseEndTime.difference(now);
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  }

  bool get hasAllHints => playerHints.length == playerIds.length;

  bool get hasAllVotes => allRequiredVotesSubmitted;

  String? getPlayerHint(String playerId) => playerHints[playerId];

  String? getPlayerVote(String playerId) => playerVotes[playerId];

  /// Returns a map of playerId → number of votes received in this round.
  Map<String, int> get voteCounts {
    final counts = <String, int>{};
    for (final votedPlayerId in playerVotes.values) {
      if (votedPlayerId != null) {
        counts[votedPlayerId] = (counts[votedPlayerId] ?? 0) + 1;
      }
    }
    return counts;
  }

  RoundInfo copyWith({
    String? id,
    String? roomId,
    Object? imposterPlayerId = _unset,
    Object? character = _unset,
    int? roundNumber,
    GamePhase? phase,
    DateTime? phaseEndTime,
    bool? imposterRevealed,
    List<String>? playerIds,
    Map<String, String?>? playerHints,
    Map<String, String?>? playerVotes,
    int? submittedVoteCount,
    int? requiredVoteCount,
  }) {
    return RoundInfo(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      imposterPlayerId: identical(imposterPlayerId, _unset)
          ? this.imposterPlayerId
          : imposterPlayerId as String?,
      character: identical(character, _unset)
          ? this.character
          : character as Character?,
      roundNumber: roundNumber ?? this.roundNumber,
      phase: phase ?? this.phase,
      phaseEndTime: phaseEndTime ?? this.phaseEndTime,
      imposterRevealed: imposterRevealed ?? this.imposterRevealed,
      playerIds: playerIds ?? this.playerIds,
      playerHints: playerHints ?? this.playerHints,
      playerVotes: playerVotes ?? this.playerVotes,
      submittedVoteCount: submittedVoteCount ?? this.submittedVoteCount,
      requiredVoteCount: requiredVoteCount ?? this.requiredVoteCount,
    );
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    imposterPlayerId,
    character,
    roundNumber,
    phase,
    phaseEndTime,
    imposterRevealed,
    playerIds,
    playerHints,
    playerVotes,
    submittedVoteCount,
    requiredVoteCount,
  ];
}

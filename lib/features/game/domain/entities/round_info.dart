import 'package:equatable/equatable.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';

enum GamePhase { hints, voting, results }

class RoundInfo extends Equatable {
  final String id;
  final String roomId;
  final String imposterPlayerId;
  final Character character;
  final int roundNumber;
  final GamePhase phase;
  final DateTime phaseEndTime;
  final bool imposterRevealed;
  final List<String> playerIds;
  final Map<String, String?> playerHints; // playerId -> hint
  final Map<String, String?> playerVotes; // voterId -> votedPlayerId

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
  });

  bool isImposter(String playerId) => playerId == imposterPlayerId;

  int get remainingSeconds {
    final now = DateTime.now().toUtc();
    final difference = phaseEndTime.difference(now);
    return difference.inSeconds > 0 ? difference.inSeconds : 0;
  }

  bool get hasAllHints => playerHints.length == playerIds.length;

  bool get hasAllVotes => playerVotes.length == playerIds.length;

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
    String? imposterPlayerId,
    Character? character,
    int? roundNumber,
    GamePhase? phase,
    DateTime? phaseEndTime,
    bool? imposterRevealed,
    List<String>? playerIds,
    Map<String, String?>? playerHints,
    Map<String, String?>? playerVotes,
  }) {
    return RoundInfo(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      imposterPlayerId: imposterPlayerId ?? this.imposterPlayerId,
      character: character ?? this.character,
      roundNumber: roundNumber ?? this.roundNumber,
      phase: phase ?? this.phase,
      phaseEndTime: phaseEndTime ?? this.phaseEndTime,
      imposterRevealed: imposterRevealed ?? this.imposterRevealed,
      playerIds: playerIds ?? this.playerIds,
      playerHints: playerHints ?? this.playerHints,
      playerVotes: playerVotes ?? this.playerVotes,
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
  ];
}

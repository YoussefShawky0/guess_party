import 'package:equatable/equatable.dart';

/// Lifetime counters of the signed-in player. Games and rounds played count
/// both modes; wins, impostor rounds, escapes and votes are Online-only.
class PlayerStats extends Equatable {
  final int gamesPlayed;
  final int gamesWon;
  final int roundsPlayed;
  final int roundsAsImposter;
  final int imposterEscapes;
  final int correctVotes;

  const PlayerStats({
    required this.gamesPlayed,
    required this.gamesWon,
    required this.roundsPlayed,
    required this.roundsAsImposter,
    required this.imposterEscapes,
    required this.correctVotes,
  });

  static const empty = PlayerStats(
    gamesPlayed: 0,
    gamesWon: 0,
    roundsPlayed: 0,
    roundsAsImposter: 0,
    imposterEscapes: 0,
    correctVotes: 0,
  );

  @override
  List<Object?> get props => [
    gamesPlayed,
    gamesWon,
    roundsPlayed,
    roundsAsImposter,
    imposterEscapes,
    correctVotes,
  ];
}

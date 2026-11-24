import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

class PlayerStatsModel extends PlayerStats {
  const PlayerStatsModel({
    required super.gamesPlayed,
    required super.gamesWon,
    required super.roundsPlayed,
    required super.roundsAsImposter,
    required super.imposterEscapes,
    required super.correctVotes,
  });

  /// Missing or non-numeric keys count as 0.
  factory PlayerStatsModel.fromJson(Map<String, dynamic> json) {
    int read(String key) {
      final value = json[key];
      return value is num ? value.toInt() : 0;
    }

    return PlayerStatsModel(
      gamesPlayed: read('games_played'),
      gamesWon: read('games_won'),
      roundsPlayed: read('rounds_played'),
      roundsAsImposter: read('rounds_as_imposter'),
      imposterEscapes: read('imposter_escapes'),
      correctVotes: read('correct_votes'),
    );
  }
}

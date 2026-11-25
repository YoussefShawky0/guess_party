import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/stats/data/models/player_stats_model.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

void main() {
  test('parses every key', () {
    final stats = PlayerStatsModel.fromJson({
      'games_played': 7,
      'games_won': 3,
      'rounds_played': 20,
      'rounds_as_imposter': 5,
      'imposter_escapes': 2,
      'correct_votes': 9,
    });
    expect(
      stats.props,
      const PlayerStats(
        gamesPlayed: 7,
        gamesWon: 3,
        roundsPlayed: 20,
        roundsAsImposter: 5,
        imposterEscapes: 2,
        correctVotes: 9,
      ).props,
    );
  });

  test('missing or invalid keys become 0', () {
    expect(PlayerStatsModel.fromJson(const {}).props, PlayerStats.empty.props);
    final partial = PlayerStatsModel.fromJson({
      'games_played': 4,
      'games_won': null,
      'correct_votes': 'x',
    });
    expect(partial.gamesPlayed, 4);
    expect(partial.gamesWon, 0);
    expect(partial.correctVotes, 0);
  });

  test('accepts doubles from json numbers', () {
    expect(PlayerStatsModel.fromJson({'games_played': 3.0}).gamesPlayed, 3);
  });
}

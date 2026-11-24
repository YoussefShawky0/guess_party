import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

BadgeProgress _of(List<BadgeProgress> all, BadgeId id) =>
    all.firstWhere((b) => b.id == id);

PlayerStats _stats({
  int games = 0,
  int wins = 0,
  int escapes = 0,
  int votes = 0,
}) => PlayerStats(
  gamesPlayed: games,
  gamesWon: wins,
  roundsPlayed: 0,
  roundsAsImposter: 0,
  imposterEscapes: escapes,
  correctVotes: votes,
);

void main() {
  test('empty stats unlock nothing and list every badge in order', () {
    final badges = evaluateBadges(PlayerStats.empty);
    expect(badges.map((b) => b.id), BadgeId.values);
    expect(badges.any((b) => b.unlocked), isFalse);
    expect(badges.every((b) => b.current == 0), isTrue);
  });

  test('targets match the spec', () {
    final targets = {
      for (final b in evaluateBadges(PlayerStats.empty)) b.id: b.target,
    };
    expect(targets, {
      BadgeId.firstGame: 1,
      BadgeId.regular: 10,
      BadgeId.veteran: 50,
      BadgeId.champion: 10,
      BadgeId.masterOfDisguise: 5,
      BadgeId.detective: 20,
    });
  });

  test('game based badges unlock at their thresholds', () {
    var b = evaluateBadges(_stats(games: 1));
    expect(_of(b, BadgeId.firstGame).unlocked, isTrue);
    expect(_of(b, BadgeId.regular).unlocked, isFalse);
    expect(_of(b, BadgeId.regular).current, 1);

    b = evaluateBadges(_stats(games: 10));
    expect(_of(b, BadgeId.regular).unlocked, isTrue);
    expect(_of(b, BadgeId.veteran).unlocked, isFalse);

    b = evaluateBadges(_stats(games: 50));
    expect(_of(b, BadgeId.veteran).unlocked, isTrue);
  });

  test('wins, escapes and correct votes drive their own badges', () {
    final b = evaluateBadges(_stats(wins: 10, escapes: 4, votes: 20));
    expect(_of(b, BadgeId.champion).unlocked, isTrue);
    expect(_of(b, BadgeId.masterOfDisguise).unlocked, isFalse);
    expect(_of(b, BadgeId.masterOfDisguise).current, 4);
    expect(_of(b, BadgeId.detective).unlocked, isTrue);
  });

  test('current is capped at the target', () {
    final b = evaluateBadges(
      _stats(games: 500, wins: 400, escapes: 99, votes: 99),
    );
    for (final badge in b) {
      expect(badge.current, badge.target);
      expect(badge.unlocked, isTrue);
    }
  });

  test('newlyUnlocked returns only unlocked badges not yet seen', () {
    final now = evaluateBadges(_stats(games: 10));
    expect(newlyUnlocked({}, now), {BadgeId.firstGame, BadgeId.regular});
    expect(newlyUnlocked({BadgeId.firstGame}, now), {BadgeId.regular});
    expect(newlyUnlocked({BadgeId.firstGame, BadgeId.regular}, now), isEmpty);
    expect(newlyUnlocked({}, evaluateBadges(PlayerStats.empty)), isEmpty);
  });
}

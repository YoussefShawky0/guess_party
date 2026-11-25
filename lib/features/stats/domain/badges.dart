import 'package:equatable/equatable.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

enum BadgeId {
  firstGame,
  regular,
  veteran,
  champion,
  masterOfDisguise,
  detective,
}

class BadgeProgress extends Equatable {
  final BadgeId id;

  /// Progress so far, never above [target].
  final int current;
  final int target;

  const BadgeProgress({
    required this.id,
    required this.current,
    required this.target,
  });

  bool get unlocked => current >= target;

  @override
  List<Object?> get props => [id, current, target];
}

int _target(BadgeId id) => switch (id) {
  BadgeId.firstGame => 1,
  BadgeId.regular => 10,
  BadgeId.veteran => 50,
  BadgeId.champion => 10,
  BadgeId.masterOfDisguise => 5,
  BadgeId.detective => 20,
};

int _value(BadgeId id, PlayerStats s) => switch (id) {
  BadgeId.firstGame || BadgeId.regular || BadgeId.veteran => s.gamesPlayed,
  BadgeId.champion => s.gamesWon,
  BadgeId.masterOfDisguise => s.imposterEscapes,
  BadgeId.detective => s.correctVotes,
};

/// Progress of every badge, in [BadgeId] order.
List<BadgeProgress> evaluateBadges(PlayerStats stats) {
  return [
    for (final id in BadgeId.values)
      BadgeProgress(
        id: id,
        current: _value(id, stats).clamp(0, _target(id)),
        target: _target(id),
      ),
  ];
}

/// Unlocked badges in [now] that are not in [seen].
Set<BadgeId> newlyUnlocked(Set<BadgeId> seen, List<BadgeProgress> now) {
  return {
    for (final badge in now)
      if (badge.unlocked && !seen.contains(badge.id)) badge.id,
  };
}

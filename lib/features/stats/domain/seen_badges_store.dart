import 'package:guess_party/features/stats/domain/badges.dart';

/// Remembers which unlocked badges the player was already told about.
abstract interface class SeenBadgesStore {
  Future<Set<BadgeId>> read();
  Future<void> write(Set<BadgeId> seen);
}

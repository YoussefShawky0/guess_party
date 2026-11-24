import 'package:equatable/equatable.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

/// The few numbers Home shows (trophy chip, guest banner, profile sheet).
///
/// Read-only: computing it never marks badges as seen, so the Game Over
/// "new badge" moment stays intact.
class BadgeSummary extends Equatable {
  final int unlocked;
  final int total;
  final int gamesPlayed;
  final int gamesWon;

  const BadgeSummary({
    required this.unlocked,
    required this.total,
    required this.gamesPlayed,
    this.gamesWon = 0,
  });

  factory BadgeSummary.fromStats(PlayerStats stats) {
    final badges = evaluateBadges(stats);
    return BadgeSummary(
      unlocked: badges.where((b) => b.unlocked).length,
      total: badges.length,
      gamesPlayed: stats.gamesPlayed,
      gamesWon: stats.gamesWon,
    );
  }

  /// Null when [json] is not a valid summary (corrupt cache).
  static BadgeSummary? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final unlocked = json['unlocked'];
    final total = json['total'];
    final gamesPlayed = json['gamesPlayed'];
    if (unlocked is! int || total is! int || gamesPlayed is! int) return null;
    final gamesWon = json['gamesWon'];
    return BadgeSummary(
      unlocked: unlocked,
      total: total,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon is int ? gamesWon : 0,
    );
  }

  Map<String, Object> toJson() => {
    'unlocked': unlocked,
    'total': total,
    'gamesPlayed': gamesPlayed,
    'gamesWon': gamesWon,
  };

  @override
  List<Object?> get props => [unlocked, total, gamesPlayed, gamesWon];
}

/// Per-user cache of the last [BadgeSummary], so Home can show the trophy
/// count instantly.
abstract class BadgeSummaryStore {
  Future<BadgeSummary?> read(String userId);
  Future<void> write(String userId, BadgeSummary summary);
  Future<void> clear(String userId);
}

/// Remembers that a user dismissed the "secure your account" banner.
abstract class GuestBannerStore {
  Future<bool> isDismissed(String userId);
  Future<void> dismiss(String userId);
}

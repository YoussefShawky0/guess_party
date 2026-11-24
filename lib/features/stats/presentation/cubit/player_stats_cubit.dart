import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/features/stats/domain/seen_badges_store.dart';

sealed class PlayerStatsState extends Equatable {
  const PlayerStatsState();

  @override
  List<Object?> get props => [];
}

final class StatsLoading extends PlayerStatsState {
  const StatsLoading();
}

final class StatsLoaded extends PlayerStatsState {
  final PlayerStats stats;
  final List<BadgeProgress> badges;

  /// Badges unlocked since the player last saw them.
  final Set<BadgeId> newBadges;

  const StatsLoaded({
    required this.stats,
    required this.badges,
    this.newBadges = const {},
  });

  @override
  List<Object?> get props => [stats, badges, newBadges];
}

final class StatsFailed extends PlayerStatsState {
  final AppErrorCode code;

  const StatsFailed(this.code);

  @override
  List<Object?> get props => [code];
}

class PlayerStatsCubit extends Cubit<PlayerStatsState> {
  final StatsRepository _repository;
  final SeenBadgesStore _seenStore;

  PlayerStatsCubit({
    required StatsRepository repository,
    required SeenBadgesStore seenBadgesStore,
    AnalyticsService analytics = const NoopAnalyticsService(),
  }) : _repository = repository,
       _seenStore = seenBadgesStore,
       _analytics = analytics,
       super(const StatsLoading());

  final AnalyticsService _analytics;

  /// Call once when the stats screen opens (not for the Game Over card).
  void trackViewed() => _analytics.track(const StatsViewedEvent());

  /// Fetches the stats, works out which badges are new, then marks them seen.
  /// Reloading while content is shown keeps it on screen.
  Future<void> load() async {
    if (isClosed) return;
    if (state is! StatsLoaded) emit(const StatsLoading());

    final result = await _repository.getMyStats();
    if (isClosed) return;

    final stats = result.fold<PlayerStats?>((_) => null, (s) => s);
    if (stats == null) {
      final code = result.fold((f) => f.code, (_) => AppErrorCode.unknown);
      emit(StatsFailed(code));
      return;
    }

    final badges = evaluateBadges(stats);
    var newBadges = <BadgeId>{};
    try {
      final seen = await _seenStore.read();
      newBadges = newlyUnlocked(seen, badges);
      if (newBadges.isNotEmpty) {
        await _seenStore.write({...seen, ...newBadges});
        for (final badge in newBadges) {
          _analytics.track(BadgeUnlockedEvent(badge: badge.name));
        }
      }
    } catch (_) {
      // Storage trouble must not hide the stats; just skip the celebration.
      newBadges = {};
    }
    if (isClosed) return;
    emit(StatsLoaded(stats: stats, badges: badges, newBadges: newBadges));
  }
}

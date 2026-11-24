import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';

import '../../../../helpers/recording_analytics.dart';
import '../../../../helpers/stats_fakes.dart';

void main() {
  test('starts loading', () async {
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(const Right(statsOneGame)),
      seenBadgesStore: FakeSeenBadgesStore(),
    );
    expect(cubit.state, const StatsLoading());
    await cubit.close();
  });

  test(
    'new badges are computed then saved; the second load has none',
    () async {
      final store = FakeSeenBadgesStore();
      final cubit = PlayerStatsCubit(
        repository: FakeStatsRepository(const Right(statsOneGame)),
        seenBadgesStore: store,
      );

      await cubit.load();
      var state = cubit.state as StatsLoaded;
      expect(state.stats, statsOneGame);
      expect(state.newBadges, {BadgeId.firstGame});
      expect(store.seen, {BadgeId.firstGame});

      await cubit.load();
      state = cubit.state as StatsLoaded;
      expect(state.newBadges, isEmpty);
      expect(store.writes, 1);
      await cubit.close();
    },
  );

  test('already seen badges are not new', () async {
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(const Right(statsOneGame)),
      seenBadgesStore: FakeSeenBadgesStore({BadgeId.firstGame}),
    );
    await cubit.load();
    expect((cubit.state as StatsLoaded).newBadges, isEmpty);
    await cubit.close();
  });

  test('failure emits StatsFailed and leaves the store alone', () async {
    final store = FakeSeenBadgesStore();
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(statsFailure),
      seenBadgesStore: store,
    );

    await cubit.load();

    expect(cubit.state, const StatsFailed(AppErrorCode.network));
    expect(store.writes, 0);
    await cubit.close();
  });

  test('retry after a failure goes through loading again', () async {
    final repo = FakeStatsRepository(statsFailure);
    final cubit = PlayerStatsCubit(
      repository: repo,
      seenBadgesStore: FakeSeenBadgesStore(),
    );
    await cubit.load();
    expect(cubit.state, isA<StatsFailed>());

    repo.result = const Right(statsOneGame);
    final future = cubit.load();
    expect(cubit.state, const StatsLoading());
    await future;
    expect(cubit.state, isA<StatsLoaded>());
    await cubit.close();
  });

  test('badge_unlocked is logged once per new badge, not on reload', () async {
    final analytics = RecordingAnalytics();
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(const Right(statsOneGame)),
      seenBadgesStore: FakeSeenBadgesStore(),
      analytics: analytics,
    );

    await cubit.load();
    await cubit.load();

    expect(analytics.events, hasLength(1));
    expect(analytics.events.single, isA<BadgeUnlockedEvent>());
    expect(analytics.events.single.params, {'badge': 'firstGame'});
    await cubit.close();
  });

  test('stats_viewed is logged by trackViewed only', () async {
    final analytics = RecordingAnalytics();
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(statsFailure),
      seenBadgesStore: FakeSeenBadgesStore(),
      analytics: analytics,
    );

    await cubit.load();
    expect(analytics.events, isEmpty);

    cubit.trackViewed();
    expect(analytics.names, ['stats_viewed']);
    await cubit.close();
  });

  test('does not emit after close', () async {
    final cubit = PlayerStatsCubit(
      repository: FakeStatsRepository(const Right(statsOneGame)),
      seenBadgesStore: FakeSeenBadgesStore(),
    );
    final future = cubit.load();
    await cubit.close();
    await future;
    expect(cubit.state, const StatsLoading());
  });
}

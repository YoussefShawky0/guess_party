import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/stats/data/shared_prefs_badge_summary_store.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/presentation/cubit/badge_summary_cubit.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/game_ui_helpers.dart';
import '../../../../helpers/stats_fakes.dart';

// Unlocks firstGame, regular and champion: 3 of 6.
const _threeBadges = PlayerStats(
  gamesPlayed: 10,
  gamesWon: 10,
  roundsPlayed: 30,
  roundsAsImposter: 3,
  imposterEscapes: 1,
  correctVotes: 4,
);

BadgeSummaryCubit _cubit(
  FakeStatsRepository repo,
  BadgeSummaryStore store, {
  String userId = 'u1',
}) => BadgeSummaryCubit(repository: repo, store: store, userId: userId);

void main() {
  test('summary counts unlocked badges and keeps games played', () {
    final summary = BadgeSummary.fromStats(_threeBadges);
    expect(summary.unlocked, 3);
    expect(summary.total, 6);
    expect(summary.gamesPlayed, 10);
    expect(BadgeSummary.tryFromJson(summary.toJson()), summary);
    expect(BadgeSummary.tryFromJson('nope'), isNull);
    expect(BadgeSummary.tryFromJson({'unlocked': 'x'}), isNull);
  });

  test('shows the cached value first, then the refreshed one', () async {
    final store = FakeBadgeSummaryStore(
      initial: {
        'u1': const BadgeSummary(unlocked: 2, total: 6, gamesPlayed: 5),
      },
    );
    final repo = GateStatsRepository();
    final cubit = BadgeSummaryCubit(
      repository: repo,
      store: store,
      userId: 'u1',
    );
    addTearDown(cubit.close);
    final states = <BadgeSummary?>[];
    cubit.stream.listen(states.add);

    final loading = cubit.load();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state?.unlocked, 2);

    repo.completer.complete(const Right(_threeBadges));
    await loading;
    await Future<void>.delayed(Duration.zero);

    expect(states.map((s) => s?.unlocked), [2, 3]);
    expect(store.summaries['u1']?.unlocked, 3);
  });

  test(
    'a failed refresh keeps the cache; with no cache it stays null',
    () async {
      final cached = FakeBadgeSummaryStore(
        initial: {
          'u1': const BadgeSummary(unlocked: 2, total: 6, gamesPlayed: 5),
        },
      );
      final withCache = _cubit(FakeStatsRepository(statsFailure), cached);
      addTearDown(withCache.close);
      await withCache.load();
      expect(withCache.state?.unlocked, 2);

      final empty = _cubit(
        FakeStatsRepository(statsFailure),
        FakeBadgeSummaryStore(),
      );
      addTearDown(empty.close);
      await empty.load();
      expect(empty.state, isNull);
    },
  );

  test(
    'never touches the seen-badges store, so Game Over still celebrates',
    () async {
      final seen = FakeSeenBadgesStore();
      final repo = FakeStatsRepository(const Right(_threeBadges));

      final summary = _cubit(repo, FakeBadgeSummaryStore());
      addTearDown(summary.close);
      await summary.load();
      expect(summary.state?.unlocked, 3);
      expect(seen.writes, 0);
      expect(seen.seen, isEmpty);

      // The Game Over cubit still sees every badge as new afterwards.
      final gameOver = PlayerStatsCubit(
        repository: repo,
        seenBadgesStore: seen,
      );
      addTearDown(gameOver.close);
      await gameOver.load();
      expect((gameOver.state as StatsLoaded).newBadges, hasLength(3));
    },
  );

  group('SharedPreferences cache', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('is keyed by user id', () async {
      const store = SharedPrefsBadgeSummaryStore();
      final repo = FakeStatsRepository(const Right(_threeBadges));
      final a = _cubit(repo, store, userId: 'a');
      addTearDown(a.close);
      await a.load();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('stats.summary.a'), isTrue);
      expect(prefs.containsKey('stats.summary.b'), isFalse);
      expect((await store.read('a'))?.unlocked, 3);
      expect(await store.read('b'), isNull);

      // Another user starts with nothing, not with the previous user's value.
      final b = _cubit(FakeStatsRepository(statsFailure), store, userId: 'b');
      addTearDown(b.close);
      await b.load();
      expect(b.state, isNull);
    });

    test('is cleared on logout', () async {
      const store = SharedPrefsBadgeSummaryStore();
      final cubit = _cubit(
        FakeStatsRepository(const Right(_threeBadges)),
        store,
        userId: 'a',
      );
      addTearDown(cubit.close);
      await cubit.load();
      expect(await store.read('a'), isNotNull);

      await cubit.clear();
      expect(cubit.state, isNull);
      expect(await store.read('a'), isNull);
    });

    test('a corrupt cache entry is ignored', () async {
      SharedPreferences.setMockInitialValues({'stats.summary.a': '{oops'});
      expect(await const SharedPrefsBadgeSummaryStore().read('a'), isNull);
    });

    test('guest banner dismissal is per user', () async {
      const store = SharedPrefsBadgeSummaryStore();
      expect(await store.isDismissed('a'), isFalse);
      await store.dismiss('a');
      expect(await store.isDismissed('a'), isTrue);
      expect(await store.isDismissed('b'), isFalse);
    });
  });
}

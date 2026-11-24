import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/views/home_view.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/features/stats/presentation/cubit/badge_summary_cubit.dart';
import 'package:guess_party/l10n/app_localizations.dart';
import 'package:guess_party/shared/design/game_button.dart';

import '../../../../helpers/game_ui_helpers.dart';
import '../../../../helpers/stats_fakes.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  distribution: AppDistribution.internal,
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'sb_publishable_test',
  sentryDsn: null,
  sentryTracesSampleRate: 0,
  sentryRelease: null,
  sentryDist: null,
);

const _cachedTwo = BadgeSummary(unlocked: 2, total: 6, gamesPlayed: 5);

// Unlocks firstGame, regular and champion: 3 of 6.
const _threeBadges = PlayerStats(
  gamesPlayed: 10,
  gamesWon: 10,
  roundsPlayed: 30,
  roundsAsImposter: 3,
  imposterEscapes: 1,
  correctVotes: 4,
);

Finder _faIcon(FaIconData icon) => find.byWidgetPredicate(
  (w) => w is FaIcon && w.icon?.codePoint == icon.codePoint,
);

class _Harness {
  _Harness(UserInfo user, FakeBadgeSummaryStore? store)
    : repo = FakeHomeRepository(user),
      summaryStore = store ?? FakeBadgeSummaryStore();

  final FakeHomeRepository repo;
  final FakeBadgeSummaryStore summaryStore;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  UserInfo user = fullUser,
  StatsRepository? stats,
  FakeBadgeSummaryStore? store,
  Locale locale = const Locale('en'),
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final h = _Harness(user, store);
  final StatsRepository statsRepo = stats ?? FakeStatsRepository(statsFailure);
  final summaryCubit = BadgeSummaryCubit(
    repository: statsRepo,
    store: h.summaryStore,
    userId: user.id,
  );
  final homeCubit = HomeCubit(repository: h.repo);
  addTearDown(summaryCubit.close);
  addTearDown(homeCubit.close);

  Widget page(String name) => Scaffold(body: Text(name));
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: homeCubit..loadUserInfo()),
            BlocProvider.value(value: summaryCubit..load()),
          ],
          child: HomeView(config: _config, bannerStore: h.summaryStore),
        ),
      ),
      for (final route in [
        AppRoutes.accountUpgrade,
        AppRoutes.stats,
        AppRoutes.settings,
        AppRoutes.createRoom,
        AppRoutes.joinRoom,
      ])
        GoRoute(path: route, builder: (_, __) => page('page:$route')),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.darkTheme,
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await _settle(tester);
  return h;
}

/// The Home screen has endless animations, so never `pumpAndSettle`. The 3 s
/// also drains the update-check delay.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-profile-chip')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('has exactly two GameButtons and none of the removed widgets', (
    tester,
  ) async {
    await _pump(tester, user: guestUser);

    expect(find.byType(GameButton), findsNWidgets(2));
    expect(find.text('Create Room'), findsOneWidget);
    expect(find.text('Join Room'), findsOneWidget);
    expect(find.text("Who's the Impostor?"), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);

    expect(find.byKey(const Key('secure-account-button')), findsNothing);
    expect(find.byKey(const Key('home-stats-button')), findsNothing);
    expect(find.text('Log out'), findsNothing);
    expect(find.text('Secure this guest account'), findsNothing);
    expect(_faIcon(FontAwesomeIcons.rightFromBracket), findsNothing);
  });

  testWidgets('the two buttons and settings navigate', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Create Room'));
    await _settle(tester);
    expect(find.text('page:${AppRoutes.createRoom}'), findsOneWidget);
  });

  testWidgets('How to Play opens the existing dialog', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(const Key('home-how-to-play-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('trophy chip shows the cached count, then the refreshed one', (
    tester,
  ) async {
    final gate = GateStatsRepository();
    await _pump(
      tester,
      stats: gate,
      store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
    );

    expect(find.text('2/6'), findsOneWidget);
    expect(find.text('3/6'), findsNothing);

    gate.completer.complete(const Right(_threeBadges));
    await tester.pump();
    await tester.pump();

    expect(find.text('3/6'), findsOneWidget);
    final handle = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.byKey(const Key('home-trophy-chip'))),
      isSemantics(isButton: true, label: '3 of 6 badges'),
    );
    handle.dispose();

    await tester.tap(find.byKey(const Key('home-trophy-chip')));
    await _settle(tester);
    expect(find.text('page:${AppRoutes.stats}'), findsOneWidget);
  });

  testWidgets('trophy chip shows the icon only while the count is unknown', (
    tester,
  ) async {
    await _pump(tester); // no cache, stats fail
    expect(find.byKey(const Key('home-trophy-chip')), findsOneWidget);
    expect(_faIcon(FontAwesomeIcons.trophy), findsOneWidget);
    expect(find.textContaining('/6'), findsNothing);
  });

  group('guest banner', () {
    testWidgets('shows for a guest who played, and can be dismissed', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        user: guestUser,
        store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
      );
      expect(find.byKey(const Key('home-guest-banner')), findsOneWidget);
      expect(
        find.text('Secure your account to keep your stats'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('home-guest-banner-dismiss')));
      await tester.pump();
      expect(find.byKey(const Key('home-guest-banner')), findsNothing);
      expect(h.summaryStore.dismissed, {'u1'});
    });

    testWidgets('opens account upgrade', (tester) async {
      await _pump(
        tester,
        user: guestUser,
        store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
      );
      await tester.tap(find.byKey(const Key('home-guest-banner-open')));
      await _settle(tester);
      expect(find.text('page:${AppRoutes.accountUpgrade}'), findsOneWidget);
    });

    testWidgets('stays hidden once dismissed', (tester) async {
      final store = FakeBadgeSummaryStore(initial: {'u1': _cachedTwo})
        ..dismissed.add('u1');
      await _pump(tester, user: guestUser, store: store);
      expect(find.byKey(const Key('home-guest-banner')), findsNothing);
    });

    testWidgets('is hidden for full accounts', (tester) async {
      await _pump(
        tester,
        user: fullUser,
        store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
      );
      expect(find.byKey(const Key('home-guest-banner')), findsNothing);
    });

    testWidgets('is hidden with no data or no games played', (tester) async {
      await _pump(tester, user: guestUser); // no cache, stats fail
      expect(find.byKey(const Key('home-guest-banner')), findsNothing);
    });

    testWidgets('is hidden when the guest has played no games', (tester) async {
      await _pump(
        tester,
        user: guestUser,
        store: FakeBadgeSummaryStore(
          initial: {
            'u1': const BadgeSummary(unlocked: 0, total: 6, gamesPlayed: 0),
          },
        ),
      );
      expect(find.byKey(const Key('home-guest-banner')), findsNothing);
    });
  });

  group('profile sheet', () {
    testWidgets('lists the rows and mini stats for a guest', (tester) async {
      await _pump(
        tester,
        user: guestUser,
        store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
      );
      await _openSheet(tester);

      expect(find.byKey(const Key('profile-mini-stats')), findsOneWidget);
      expect(find.byKey(const Key('profile-secure')), findsOneWidget);
      expect(find.byKey(const Key('profile-stats')), findsOneWidget);
      expect(find.byKey(const Key('profile-logout')), findsOneWidget);
    });

    testWidgets('hides mini stats without data and the secure row for full '
        'accounts', (tester) async {
      await _pump(tester, user: fullUser);
      await _openSheet(tester);

      expect(find.byKey(const Key('profile-mini-stats')), findsNothing);
      expect(find.byKey(const Key('profile-secure')), findsNothing);
      expect(find.byKey(const Key('profile-logout')), findsOneWidget);
    });

    testWidgets('My stats opens the stats page', (tester) async {
      await _pump(tester);
      await _openSheet(tester);
      await tester.tap(find.byKey(const Key('profile-stats')));
      await _settle(tester);
      expect(find.text('page:${AppRoutes.stats}'), findsOneWidget);
    });

    testWidgets('a full account logs out directly and clears the cache', (
      tester,
    ) async {
      final store = FakeBadgeSummaryStore(initial: {'u1': _cachedTwo});
      final h = await _pump(tester, user: fullUser, store: store);
      await _openSheet(tester);

      await tester.tap(find.byKey(const Key('profile-logout')));
      await _settle(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(h.repo.signOutCalls, 1);
      expect(store.cleared, ['u1']);
    });

    testWidgets('a guest sees the dialog; barrier tap cancels', (tester) async {
      final h = await _pump(tester, user: guestUser);
      await _openSheet(tester);

      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(
        find.text(
          "You're playing as a guest. If you log out, you can't get this "
          'account or its stats back.',
        ),
        findsOneWidget,
      );
      expect(find.byType(GameButton), findsNWidgets(3));
      expect(find.text('Secure account'), findsOneWidget);
      expect(find.text('Log out anyway'), findsOneWidget);

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(AlertDialog), findsNothing);
      expect(h.repo.signOutCalls, 0);
    });

    testWidgets('a guest can log out anyway', (tester) async {
      final store = FakeBadgeSummaryStore(initial: {'u1': _cachedTwo});
      final h = await _pump(tester, user: guestUser, store: store);
      await _openSheet(tester);
      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('guest-logout-anyway')));
      await _settle(tester);

      expect(h.repo.signOutCalls, 1);
      expect(store.cleared, ['u1']);
    });

    testWidgets('Secure account in the dialog navigates and does not log out', (
      tester,
    ) async {
      final h = await _pump(tester, user: guestUser);
      await _openSheet(tester);
      await tester.tap(find.byKey(const Key('profile-logout')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.tap(find.byKey(const Key('guest-logout-secure')));
      await _settle(tester);

      expect(find.text('page:${AppRoutes.accountUpgrade}'), findsOneWidget);
      expect(h.repo.signOutCalls, 0);
    });
  });

  testWidgets('works in Arabic at 2x text without overflow', (tester) async {
    await _pump(
      tester,
      user: guestUser,
      locale: const Locale('ar'),
      textScale: 2,
      store: FakeBadgeSummaryStore(initial: {'u1': _cachedTwo}),
    );
    expect(find.text('مين الإمبوستر؟'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

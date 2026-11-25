import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:guess_party/features/stats/presentation/views/stats_view.dart';
import 'package:guess_party/l10n/app_localizations.dart';

import '../../../../helpers/stats_fakes.dart';

const _veteranish = PlayerStats(
  gamesPlayed: 12,
  gamesWon: 4,
  roundsPlayed: 40,
  roundsAsImposter: 9,
  imposterEscapes: 3,
  correctVotes: 15,
);

Future<(PlayerStatsCubit, FakeStatsRepository)> _pump(
  WidgetTester tester, {
  required FakeStatsRepository repo,
  bool isGuest = false,
}) async {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = PlayerStatsCubit(
    repository: repo,
    seenBadgesStore: FakeSeenBadgesStore(),
  );
  addTearDown(cubit.close);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => BlocProvider.value(
          value: cubit..load(),
          child: StatsView(isGuest: isGuest),
        ),
      ),
      GoRoute(
        path: AppRoutes.accountUpgrade,
        builder: (_, __) => const Scaffold(body: Text('Upgrade page')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
    ),
  );
  await tester.pumpAndSettle();
  return (cubit, repo);
}

void main() {
  testWidgets('shows stats, unlocked and locked badges', (tester) async {
    await _pump(tester, repo: FakeStatsRepository(const Right(_veteranish)));

    expect(find.text('My Stats'), findsOneWidget);
    expect(find.text('Games played'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Correct votes'), findsOneWidget);
    expect(find.text('Badges'), findsOneWidget);

    // Unlocked: no progress bar. Locked: current/target.
    expect(find.text('First Game'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('12/50'), findsOneWidget);
    expect(find.text('15/20'), findsOneWidget);
    expect(find.text('4/10'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(4));
    expect(find.byKey(const Key('stats-guest-card')), findsNothing);
  });

  testWidgets('guest card opens the account upgrade page', (tester) async {
    await _pump(
      tester,
      repo: FakeStatsRepository(const Right(_veteranish)),
      isGuest: true,
    );

    expect(
      find.text('Create an account to keep your stats forever'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('stats-guest-upgrade')));
    await tester.pumpAndSettle();
    expect(find.text('Upgrade page'), findsOneWidget);
  });

  testWidgets('error shows retry and retry reloads', (tester) async {
    final repo = FakeStatsRepository(statsFailure);
    await _pump(tester, repo: repo);

    expect(find.text('Retry'), findsOneWidget);
    expect(repo.calls, 1);

    repo.result = const Right(_veteranish);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.text('Games played'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('pull to refresh reloads the stats', (tester) async {
    final repo = FakeStatsRepository(const Right(_veteranish));
    await _pump(tester, repo: repo);
    expect(repo.calls, 1);

    await tester.drag(find.byType(ListView), const Offset(0, 1500));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
  });
}

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/presentation/views/game_over_view.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:guess_party/l10n/app_localizations.dart';

import '../../../../helpers/stats_fakes.dart';

class _PendingStatsRepository implements StatsRepository {
  final completer = Completer<Either<Failure, PlayerStats>>();
  int calls = 0;

  @override
  ResultFuture<PlayerStats> getMyStats() {
    calls++;
    return completer.future;
  }
}

const _players = [
  Player(
    id: 'p1',
    roomId: 'room',
    userId: 'u1',
    username: 'Sam',
    score: 3,
    isHost: true,
  ),
  Player(
    id: 'p2',
    roomId: 'room',
    userId: 'u2',
    username: 'Guest',
    score: 1,
    isHost: false,
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required String gameMode,
  required StatsRepository repo,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: GameOverView(
        players: _players,
        playerScores: const {'p1': 3, 'p2': 1},
        gameMode: gameMode,
        createPlayerStatsCubit: () => PlayerStatsCubit(
          repository: repo,
          seenBadgesStore: FakeSeenBadgesStore(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('online game over shows the new-badge card', (tester) async {
    final repo = FakeStatsRepository(const Right(statsOneGame));
    await _pump(tester, gameMode: GameConstants.gameModeOnline, repo: repo);

    expect(find.byKey(const Key('new-badges-card')), findsOneWidget);
    expect(find.text('New badge unlocked!'), findsOneWidget);
    expect(find.text('First Game'), findsOneWidget);
    expect(repo.calls, 1);
  });

  testWidgets('shared-device game over never loads stats or shows the card', (
    tester,
  ) async {
    final repo = FakeStatsRepository(const Right(statsOneGame));
    await _pump(tester, gameMode: GameConstants.gameModeLocal, repo: repo);

    expect(repo.calls, 0);
    expect(find.byKey(const Key('new-badges-card')), findsNothing);
  });

  testWidgets('no card without new badges, and failures are silent', (
    tester,
  ) async {
    await _pump(
      tester,
      gameMode: GameConstants.gameModeOnline,
      repo: FakeStatsRepository(Right(PlayerStats.empty)),
    );
    expect(find.byKey(const Key('new-badges-card')), findsNothing);

    await _pump(
      tester,
      gameMode: GameConstants.gameModeOnline,
      repo: FakeStatsRepository(statsFailure),
    );
    expect(find.byKey(const Key('new-badges-card')), findsNothing);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('buttons are usable while the stats are still loading', (
    tester,
  ) async {
    final repo = _PendingStatsRepository();
    await _pump(tester, gameMode: GameConstants.gameModeOnline, repo: repo);

    expect(repo.calls, 1);
    final home = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Back to Home'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(home.onPressed, isNotNull);
    expect(find.byKey(const Key('new-badges-card')), findsNothing);

    repo.completer.complete(const Right(statsOneGame));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('new-badges-card')), findsOneWidget);
  });
}

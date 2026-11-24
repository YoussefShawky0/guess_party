import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/presentation/views/game_over_view.dart';
import 'package:guess_party/l10n/app_localizations.dart';

class _FakeAdService implements InterstitialAdService {
  int preloads = 0;
  int shows = 0;
  final closeAd = Completer<void>();

  @override
  Future<void> initialize() async {}

  @override
  void preload() => preloads++;

  @override
  Future<void> showAfterGameIfReady() {
    shows++;
    return closeAd.future;
  }
}

void main() {
  testWidgets('leaving Game Over waits for the ad, once, then goes home', (
    tester,
  ) async {
    final ads = _FakeAdService();
    const player = Player(
      id: 'p1',
      roomId: 'r1',
      userId: 'u1',
      username: 'Sam',
      score: 3,
      isHost: true,
    );
    final router = GoRouter(
      initialLocation: '/over',
      routes: [
        GoRoute(
          path: '/over',
          builder: (_, __) => GameOverView(
            players: const [player],
            playerScores: const {'p1': 3},
            adService: ads,
          ),
        ),
        GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
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
    expect(ads.preloads, 1);

    final backHome = find.byIcon(Icons.home_rounded);
    await tester.tap(backHome);
    await tester.tap(backHome);
    await tester.pump();

    expect(ads.shows, 1, reason: 'a double tap must not queue two ads');
    expect(find.text('Home'), findsNothing, reason: 'still showing the ad');

    ads.closeAd.complete();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    router.dispose();
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/game_end_navigation_listener.dart';

void main() {
  testWidgets('repeated GameEnded events navigate to game over exactly once', (
    tester,
  ) async {
    final states = StreamController<GameState>.broadcast();
    var gameOverBuilds = 0;
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          builder: (_, __) => GameEndNavigationListener(
            roomId: 'room-1',
            states: states.stream,
            child: const Scaffold(body: Text('Game')),
          ),
        ),
        GoRoute(
          path: '/room/:roomId/game-over',
          builder: (_, __) {
            gameOverBuilds++;
            return const Scaffold(body: Text('Game Over'));
          },
        ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    const ended = GameEnded('Game Over', players: [], playerScores: {});
    states.add(ended);
    states.add(ended);
    await tester.pumpAndSettle();

    expect(find.text('Game Over'), findsOneWidget);
    expect(gameOverBuilds, 1);
    await states.close();
    router.dispose();
  });
}

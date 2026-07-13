import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/game/presentation/views/widgets/game_connection_feedback.dart';

void main() {
  Widget harness(bool reconnecting) => MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: GameConnectionFeedback(
        isReconnecting: reconnecting,
        child: const Text('Phase content'),
      ),
    ),
  );

  testWidgets('shows connection feedback only while reconnecting', (
    tester,
  ) async {
    await tester.pumpWidget(harness(false));
    expect(find.text('Phase content'), findsOneWidget);
    expect(find.byKey(const Key('game-reconnecting-feedback')), findsNothing);

    await tester.pumpWidget(harness(true));
    expect(find.byKey(const Key('game-reconnecting-feedback')), findsOneWidget);
    expect(find.text('Reconnecting to game...'), findsOneWidget);
  });
}

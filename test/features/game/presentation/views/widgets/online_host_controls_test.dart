import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/views/widgets/online_game_content.dart';
import 'package:guess_party/core/theme/app_theme.dart';

void main() {
  Widget harness(Widget child) => MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  );

  testWidgets('unresolved online identity renders neutral sync feedback', (
    tester,
  ) async {
    await tester.pumpWidget(harness(const OnlineRoleSyncCard()));
    expect(find.text('Syncing your role...'), findsOneWidget);
    expect(find.textContaining('Impostor'), findsNothing);
  });

  testWidgets('host sees hints skip control and can confirm it', (
    tester,
  ) async {
    var hintsSkips = 0;
    await tester.pumpWidget(
      harness(
        OnlineHostControls(
          phase: GamePhase.hints,
          isHost: true,
          onSkipHints: () => hintsSkips++,
          onSkipVoting: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('online-host-skip-control')), findsOneWidget);
    await tester.tap(find.text('Skip to Voting'));
    await tester.pumpAndSettle();
    expect(
      find.text('Are you sure you want to skip to voting?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(hintsSkips, 1);
  });

  testWidgets('non-host cannot see online host controls', (tester) async {
    await tester.pumpWidget(
      harness(
        OnlineHostControls(
          phase: GamePhase.voting,
          isHost: false,
          onSkipHints: () {},
          onSkipVoting: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('online-host-skip-control')), findsNothing);
    expect(find.text('Skip to Results'), findsNothing);
  });
}

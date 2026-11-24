import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/shared/design/animated_game_background.dart';

import '../../helpers/game_ui_helpers.dart';

void main() {
  Widget background({
    bool disableAnimations = false,
    Duration idleTimeout = const Duration(seconds: 60),
    bool tickersEnabled = true,
  }) => gameTestApp(
    disableAnimations: disableAnimations,
    home: Scaffold(
      body: TickerMode(
        enabled: tickersEnabled,
        child: AnimatedGameBackground(
          idleTimeout: idleTimeout,
          child: const Center(child: Text('content')),
        ),
      ),
    ),
  );

  testWidgets('animates by default and shows its child', (tester) async {
    await tester.pumpWidget(background());
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('content'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('is static with disableAnimations (no active ticker)', (
    tester,
  ) async {
    await tester.pumpWidget(background(disableAnimations: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('pauses on lifecycle paused and resumes', (tester) async {
    await tester.pumpWidget(background());
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('pauses while the ticker mode is off', (tester) async {
    await tester.pumpWidget(background(tickersEnabled: false));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('stops after the idle timeout and a pointer resumes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      background(idleTimeout: const Duration(seconds: 5)),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    final gesture = await tester.startGesture(const Offset(50, 50));
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await gesture.up();
  });
}

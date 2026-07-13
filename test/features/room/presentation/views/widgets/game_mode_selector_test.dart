import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/room/presentation/views/widgets/game_mode_selector.dart';

void main() {
  testWidgets('labels the local storage mode as connected Shared Device', (
    tester,
  ) async {
    String? selectedMode;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: GameModeSelector(
            selectedMode: GameConstants.gameModeOnline,
            onModeChanged: (mode) => selectedMode = mode,
          ),
        ),
      ),
    );

    expect(find.text('Shared Device'), findsOneWidget);
    expect(find.text('Pass & play on one connected device'), findsOneWidget);

    await tester.tap(find.text('Shared Device'));

    expect(selectedMode, GameConstants.gameModeLocal);
  });

  testWidgets('explains the Shared-Device connectivity requirements', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: SharedDeviceConnectivityNotice(isTablet: false),
        ),
      ),
    );

    expect(
      find.byKey(const Key('shared-device-connectivity-notice')),
      findsOneWidget,
    );
    expect(find.textContaining('internet connection'), findsOneWidget);
    expect(find.textContaining('active signed-in session'), findsOneWidget);
    expect(find.textContaining('pass this device'), findsOneWidget);
  });
}

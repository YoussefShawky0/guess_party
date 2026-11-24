import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/room/presentation/views/widgets/local_players_input.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  testWidgets('pre-fills initialNames and reports them once', (tester) async {
    final reports = <List<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: LocalPlayersInput(
              maxPlayers: 4,
              initialNames: const ['Host', 'Ann', 'Bob'],
              onPlayersChanged: reports.add,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Host'), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    expect(reports, [
      ['Host', 'Ann', 'Bob'],
    ]);
  });
}

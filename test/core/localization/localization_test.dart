import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  testWidgets('English exposes localized core controls at large text scale', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _LocalizedHarness(
        locale: const Locale('en'),
        textScaler: const TextScaler.linear(2),
      ),
    );

    expect(find.text('Shared Device'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
    expect(find.byType(Semantics), findsWidgets);
    semantics.dispose();
  });

  testWidgets('Arabic uses RTL and localized labels', (tester) async {
    await tester.pumpWidget(
      _LocalizedHarness(
        locale: const Locale('ar'),
        textScaler: const TextScaler.linear(1.3),
      ),
    );

    expect(find.text('جهاز مشترك'), findsOneWidget);
    expect(find.text('بدء اللعبة'), findsOneWidget);
    expect(find.text('Guess Party'), findsOneWidget);
    expect(find.text('مرحبًا، زياد!'), findsOneWidget);
    expect(find.text('هل أنت مستعد لاكتشاف المحتال؟'), findsOneWidget);
    expect(find.text('تم اكتشاف المحتال'), findsOneWidget);
    expect(find.text('نتائج التصويت'), findsOneWidget);
    expect(find.text('الأكثر تصويتًا: زياد (2 صوتًا)'), findsOneWidget);
    final direction = tester.widget<Directionality>(
      find.byType(Directionality).first,
    );
    expect(direction.textDirection, TextDirection.rtl);
  });

  testWidgets('English core labels remain available at supported text scales', (
    tester,
  ) async {
    for (final scale in <double>[1.0, 1.3, 2.0]) {
      await tester.pumpWidget(
        _LocalizedHarness(
          locale: const Locale('en'),
          textScaler: TextScaler.linear(scale),
        ),
      );
      expect(find.text('Shared Device'), findsOneWidget);
      expect(find.text('Start Game'), findsOneWidget);
    }
  });
}

class _LocalizedHarness extends StatelessWidget {
  const _LocalizedHarness({required this.locale, required this.textScaler});

  final Locale locale;
  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: child!,
        ),
      ),
      home: Builder(
        builder: (context) => SingleChildScrollView(
          child: Column(
            children: [
              Text(AppLocalizations.of(context).appName),
              Text(AppLocalizations.of(context).sharedDeviceMode),
              Text(AppLocalizations.of(context).welcomeUser('زياد')),
              Text(AppLocalizations.of(context).readyToFindImposter),
              Text(AppLocalizations.of(context).imposterCaughtTitle),
              Text(AppLocalizations.of(context).votingResults),
              Text(AppLocalizations.of(context).mostVoted('زياد', 2)),
              Semantics(
                button: true,
                label: AppLocalizations.of(context).startGame,
                child: Text(AppLocalizations.of(context).startGame),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

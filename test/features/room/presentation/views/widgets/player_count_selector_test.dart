import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/room/presentation/views/widgets/player_count_selector.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  testWidgets('keeps the fixed 4, 6, 8, and 10 player options', (tester) async {
    await _pumpSelector(tester);

    for (final count in <int>[4, 6, 8, 10]) {
      expect(find.widgetWithText(ChoiceChip, '$count players'), findsOneWidget);
    }
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '4 players'))
          .selected,
      isTrue,
    );
  });

  testWidgets('fixed and custom selections are mutually exclusive', (
    tester,
  ) async {
    final changes = <int?>[];
    await _pumpSelector(tester, onChanged: changes.add);

    await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
    await tester.pump();

    for (final count in <int>[4, 6, 8, 10]) {
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, '$count players'),
            )
            .selected,
        isFalse,
      );
    }
    expect(changes.last, isNull);

    await tester.enterText(find.byKey(CustomPlayerCountOption.fieldKey), '7');
    await tester.pump();
    expect(changes.last, 7);

    await tester.tap(find.widgetWithText(ChoiceChip, '6 players'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '6 players'))
          .selected,
      isTrue,
    );
    expect(changes.last, 6);
  });

  testWidgets('shows the 4-10 custom range hint', (tester) async {
    await _pumpSelector(tester);

    expect(find.text('4-10'), findsOneWidget);
  });

  for (final value in <String>['4', '5', '7', '9', '10']) {
    testWidgets('accepts custom player count $value', (tester) async {
      final changes = <int?>[];
      await _pumpSelector(tester, onChanged: changes.add);

      await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
      await tester.enterText(
        find.byKey(CustomPlayerCountOption.fieldKey),
        value,
      );
      await tester.pump();

      expect(changes.last, int.parse(value));
      expect(find.text('Enter a number from 4 to 10'), findsNothing);
      expect(find.text('Enter a whole number'), findsNothing);
    });
  }

  for (final invalid in <String>[
    '0',
    '3',
    '11',
    '-1',
    '999999999999999999999999999999999999',
  ]) {
    testWidgets('rejects out-of-range custom value $invalid', (tester) async {
      final changes = <int?>[];
      await _pumpSelector(tester, onChanged: changes.add);

      await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
      await tester.enterText(
        find.byKey(CustomPlayerCountOption.fieldKey),
        invalid,
      );
      await tester.pump();

      expect(changes.last, isNull);
      expect(find.text('Enter a number from 4 to 10'), findsOneWidget);
    });
  }

  for (final invalid in <String>['abc', '4.5']) {
    testWidgets('rejects non-integer custom value $invalid', (tester) async {
      final changes = <int?>[];
      await _pumpSelector(tester, onChanged: changes.add);

      await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
      await tester.enterText(
        find.byKey(CustomPlayerCountOption.fieldKey),
        invalid,
      );
      await tester.pump();

      expect(changes.last, isNull);
      expect(find.text('Enter a whole number'), findsOneWidget);
    });
  }

  testWidgets('rejects an empty active custom value', (tester) async {
    final changes = <int?>[];
    await _pumpSelector(tester, onChanged: changes.add);

    await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
    await tester.pump();

    expect(changes.last, isNull);
    expect(find.text('Enter a player count'), findsOneWidget);
  });

  testWidgets('supports Arabic RTL at 200 percent text scale', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pumpSelector(
      tester,
      locale: const Locale('ar'),
      textScaler: const TextScaler.linear(2),
    );
    await tester.tap(find.byKey(CustomPlayerCountOption.fieldKey));
    await tester.enterText(find.byKey(CustomPlayerCountOption.fieldKey), '11');
    await tester.pump();

    expect(find.text('4-10'), findsOneWidget);
    expect(find.text('أدخل عددًا من 4 إلى 10'), findsOneWidget);
    expect(
      tester
          .widget<Directionality>(find.byType(Directionality).first)
          .textDirection,
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSelector(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  ValueChanged<int?>? onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: PlayerCountSelector(
            initialValue: 4,
            onChanged: onChanged ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

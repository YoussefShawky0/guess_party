import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/views/widgets/round_header_widget.dart';
import 'package:guess_party/l10n/app_localizations.dart';

void main() {
  final ar = lookupAppLocalizations(const Locale('ar'));
  final en = lookupAppLocalizations(const Locale('en'));
  String text(AppLocalizations l10n, int seconds) =>
      RoundHeaderWidget.phaseDurationText(l10n, GamePhase.hints, seconds);

  test('the phase duration chip is localized', () {
    expect(text(ar, 300), '5 دقائق');
    expect(text(en, 300), '5 min');
  });

  test('a duration that is not whole minutes is shown in seconds', () {
    expect(text(en, 90), '90 seconds');
  });
}

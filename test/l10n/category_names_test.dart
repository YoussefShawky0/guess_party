import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/l10n/app_localizations_ar.dart';
import 'package:guess_party/l10n/l10n.dart';

void main() {
  // Keys of every active row in public.categories. A key missing from
  // categoryName() would show the English DB name in the Arabic UI.
  const liveKeys = [
    'football_players',
    'islamic_figures',
    'daily_products',
    'places',
    'foods',
    'animals',
    'professions',
    'sports',
    'transport',
    'fruits_vegetables',
    'countries',
    'clothes',
  ];

  test('every live category has an Arabic name', () {
    final ar = AppLocalizationsAr();
    for (final key in liveKeys) {
      expect(ar.categoryName(key, 'FALLBACK'), isNot('FALLBACK'), reason: key);
    }
  });

  test('unknown category falls back to the server name', () {
    expect(AppLocalizationsAr().categoryName('new_key', 'New'), 'New');
  });
}

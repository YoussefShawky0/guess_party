import 'package:flutter/widgets.dart';
import 'package:guess_party/l10n/app_localizations.dart';
import 'package:guess_party/l10n/app_localizations_en.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEn();
}

extension CategoryLocalizations on AppLocalizations {
  String categoryName(String key, String fallback) => switch (key) {
    'places' => categoryPlaces,
    'animals' => categoryAnimals,
    'football_players' => categoryFootballPlayers,
    'islamic_figures' => categoryIslamicFigures,
    'daily_products' => categoryDailyProducts,
    'foods' => categoryFoods,
    _ => fallback,
  };
}

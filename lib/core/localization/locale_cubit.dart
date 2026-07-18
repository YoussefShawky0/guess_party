import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the user-facing language preference independently of gameplay state.
/// A null state means that the device/system locale should be used.
class LocaleCubit extends Cubit<Locale?> {
  static const _localeKey = 'app_locale';

  LocaleCubit() : super(null);

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_localeKey)) {
      case 'en':
        emit(const Locale('en'));
      case 'ar':
        emit(const Locale('ar'));
      default:
        emit(null);
    }
  }

  Future<void> setLocale(Locale? locale) async {
    final normalized = switch (locale?.languageCode) {
      'en' => const Locale('en'),
      'ar' => const Locale('ar'),
      _ => null,
    };
    emit(normalized);
    final prefs = await SharedPreferences.getInstance();
    if (normalized == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, normalized.languageCode);
    }
  }
}

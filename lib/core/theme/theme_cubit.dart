import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _themeKey = 'app_theme_mode';

  ThemeCubit() : super(ThemeMode.dark);

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_themeKey);
    switch (saved) {
      case 'light':
        emit(ThemeMode.light);
      case 'system':
        emit(ThemeMode.system);
      default:
        emit(ThemeMode.dark);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    emit(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  String get currentThemeName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}

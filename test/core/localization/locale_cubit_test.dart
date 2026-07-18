import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to the system locale', () async {
    final cubit = LocaleCubit();
    await cubit.loadSavedLocale();

    expect(cubit.state, isNull);
    await cubit.close();
  });

  test('persists and restores Arabic', () async {
    final cubit = LocaleCubit();
    await cubit.setLocale(const Locale('ar'));
    await cubit.close();

    final restored = LocaleCubit();
    await restored.loadSavedLocale();
    expect(restored.state, const Locale('ar'));
    await restored.close();
  });

  test('system default clears a previously selected language', () async {
    final cubit = LocaleCubit();
    await cubit.setLocale(const Locale('en'));
    await cubit.setLocale(null);

    expect(cubit.state, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), isNull);
    await cubit.close();
  });
}

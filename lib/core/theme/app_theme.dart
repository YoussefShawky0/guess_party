import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';

class AppTheme {
  static const primaryColor = AppColors.primary;
  static const secondaryColor = AppColors.secondary;
  static const backgroundColor = AppColors.background;
  static const surfaceColor = AppColors.surface;

  /// Font family of headings and buttons (see `pubspec.yaml`).
  static const headingFontFamily = 'BalooBhaijaan2';

  static TextStyle _baloo(double weight) => TextStyle(
    fontFamily: headingFontFamily,
    fontWeight: weight >= 800 ? FontWeight.w800 : FontWeight.w700,
    fontVariations: [FontVariation('wght', weight)],
  );

  /// Baloo Bhaijaan 2 on heading and button slots only. Body styles keep the
  /// default font. Merged over the default text theme by [ThemeData].
  static TextTheme get _headingTextTheme => TextTheme(
    displayLarge: _baloo(800),
    displayMedium: _baloo(800),
    displaySmall: _baloo(800),
    headlineLarge: _baloo(800),
    headlineMedium: _baloo(800),
    headlineSmall: _baloo(800),
    titleLarge: _baloo(700),
    labelLarge: _baloo(700),
  );

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _headingTextTheme,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonPrimary,
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      extensions: const [AppColorsTheme.dark, GameTokens.dark],
    );
  }

  static ThemeData get lightTheme {
    const bg = Color(0xFFF9F7F7);
    const surface = Color(0xFFDBE2EF);
    const textDark = Color(0xFF112D4E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: bg,
      textTheme: _headingTextTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: textDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      extensions: const [AppColorsTheme.light, GameTokens.light],
    );
  }
}

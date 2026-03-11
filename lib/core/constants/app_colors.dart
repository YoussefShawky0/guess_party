import 'package:flutter/material.dart';

/// App-wide color constants for consistent theming
/// Color Palette:
/// Light Theme Colors:
/// - F9F7F7 (Off White)
/// - DBE2EF (Light Blue Gray)
/// - 3F72AF (Medium Blue)
/// - 112D4E (Dark Navy)
/// Dark Theme Colors:
/// - 0F2854 (Dark Navy)
/// - 1C4D8D (Medium Blue)
/// - 4988C4 (Sky Blue)
/// - BDE8F5 (Light Cyan)
/// - 1D546D (Teal Blue)
/// - 061E29 (Deep Dark)
class AppColors {
  AppColors._();

  // ============== Primary Colors ==============
  static const Color primary = Color(0xFF3F72AF); // Medium Blue - main brand
  static const Color primaryLight = Color(0xFF4988C4); // Sky Blue
  static const Color primaryDark = Color(0xFF112D4E); // Dark Navy

  // ============== Secondary Colors ==============
  static const Color secondary = Color(0xFF1D546D); // Teal Blue
  static const Color secondaryLight = Color(0xFFDBE2EF); // Light Blue Gray
  static const Color secondaryDark = Color(0xFF0F2854); // Dark Navy

  // ============== Background Colors ==============
  static const Color background = Color(0xFF0A1929); // Darker Navy (main bg)
  static const Color surface = Color(0xFF112D4E); // Dark Navy (cards)
  static const Color surfaceLight = Color(0xFF1C4D8D); // Medium Blue
  static const Color surfaceHighlight = Color(0xFF3F72AF); // Highlight

  // ============== Text Colors ==============
  static const Color textPrimary = Color(0xFFF9F7F7); // Off White - main text
  static const Color textSecondary = Color(0xFFDBE2EF); // Light Blue Gray
  static const Color textMuted = Color(0xFFBDE8F5); // Light Cyan
  static const Color textDark = Color(0xFF112D4E); // Dark Navy (on light bg)

  // ============== Status Colors ==============
  static const Color success = Color(0xFF22C55E); // Green
  static const Color successLight = Color(0xFFDCFCE7); // Light green bg
  static const Color successDark = Color(0xFF16A34A); // Dark green

  static const Color error = Color(0xFFEF4444); // Red
  static const Color errorLight = Color(0xFFFEE2E2); // Light red bg
  static const Color errorDark = Color(0xFFDC2626); // Dark red

  static const Color warning = Color(0xFFF59E0B); // Amber/Orange
  static const Color warningLight = Color(0xFFFEF3C7); // Light amber bg
  static const Color warningDark = Color(0xFFD97706); // Dark amber

  static const Color info = Color(0xFF3F72AF); // Medium Blue
  static const Color infoLight = Color(0xFFDBE2EF); // Light Blue Gray
  static const Color infoDark = Color(0xFF112D4E); // Dark Navy

  // ============== Game-Specific Colors ==============
  // Character Card (Non-Imposter)
  static const Color characterCardBg = Color(0xFF112D4E); // Dark Navy
  static const Color characterCardBorder = Color(
    0xFF1C4D8D,
  ); // Medium Blue border
  static const Color characterCardIcon = Color(0xFFDBE2EF); // Light Blue Gray
  static const Color characterCardText = Color(0xFFF9F7F7); // Off White
  static const Color characterCardSubtext = Color(
    0xFFDBE2EF,
  ); // Light Blue Gray

  // Imposter Card
  static const Color imposterCardBg = Color(0xFF7F1D1D); // Dark red
  static const Color imposterCardBorder = Color(0xFFEF4444); // Red border
  static const Color imposterCardIcon = Color(0xFFFCA5A5); // Light red icon
  static const Color imposterCardText = Color(0xFFF9F7F7); // Off White
  static const Color imposterCardSubtext = Color(
    0xFFFECACA,
  ); // Light red subtext

  // Voting Phase
  static const Color voteSelected = Color(0xFF22C55E); // Green for selected
  static const Color voteSelectedBg = Color(0xFF14532D); // Dark green bg
  static const Color voteUnselected = Color(0xFF3F72AF); // Medium Blue
  static const Color voteUnselectedBg = Color(0xFF1C4D8D); // Surface

  // Hints Phase
  static const Color hintCardBg = Color(0xFF112D4E); // Dark Navy
  static const Color hintCardBorder = Color(0xFF1C4D8D); // Medium Blue border
  static const Color hintIconColor = Color(
    0xFFFBBF24,
  ); // Amber/Gold for lightbulb

  // Results Phase
  static const Color resultsImposterBg = Color(0xFF7F1D1D); // Dark red
  static const Color resultsCaughtIcon = Color(0xFF22C55E); // Green check
  static const Color resultsEscapedIcon = Color(0xFFEF4444); // Red X

  // Scores
  static const Color goldMedal = Color(0xFFFBBF24); // Gold (1st place)
  static const Color silverMedal = Color(0xFFDBE2EF); // Light Blue Gray (2nd)
  static const Color bronzeMedal = Color(0xFFCD7C32); // Bronze (3rd place)
  static const Color scoreBadgeBg = Color(0xFFFBBF24); // Amber score badge
  static const Color scoreBadgeText = Color(0xFF112D4E); // Dark Navy on badge

  // Timer
  static const Color timerNormal = Color(0xFF22C55E); // Green (>30s)
  static const Color timerWarning = Color(0xFFF59E0B); // Orange (10-30s)
  static const Color timerCritical = Color(0xFFEF4444); // Red (<10s)
  static const Color timerBg = Color(0xFF112D4E); // Dark Navy

  // ============== Card Colors ==============
  static const Color cardBg = Color(0xFF112D4E); // Dark Navy
  static const Color cardBorder = Color(0xFF1C4D8D); // Medium Blue border
  static const Color cardHighlight = Color(0xFF3F72AF); // Highlight

  // ============== Button Colors ==============
  static const Color buttonPrimary = Color(0xFF3F72AF); // Medium Blue
  static const Color buttonSecondary = Color(0xFF1C4D8D); // Surface
  static const Color buttonSuccess = Color(0xFF22C55E); // Green
  static const Color buttonDanger = Color(0xFFEF4444); // Red
  static const Color buttonDisabled = Color(0xFF112D4E); // Dark Navy

  // ============== Avatar Colors ==============
  static const List<Color> avatarColors = [
    Color(0xFF3F72AF), // Medium Blue
    Color(0xFF4988C4), // Sky Blue
    Color(0xFF1D546D), // Teal Blue
    Color(0xFF22C55E), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
  ];

  /// Get avatar color based on index (cycles through available colors)
  static Color getAvatarColor(int index) {
    return avatarColors[index % avatarColors.length];
  }

  /// Returns the theme-aware colors for the current context.
  static AppColorsTheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorsTheme>()!;
}

/// Theme extension that holds all surface/text colors that change
/// between light and dark themes.
class AppColorsTheme extends ThemeExtension<AppColorsTheme> {
  const AppColorsTheme({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.inputFill,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBg,
    required this.cardBorder,
    required this.buttonSecondary,
    required this.hintCardBg,
    required this.hintCardBorder,
    required this.characterCardBg,
    required this.characterCardBorder,
    required this.characterCardText,
    required this.characterCardSubtext,
    required this.characterCardIcon,
    required this.timerBg,
    required this.voteUnselectedBg,
  });

  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color inputFill;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBg;
  final Color cardBorder;
  final Color buttonSecondary;
  final Color hintCardBg;
  final Color hintCardBorder;
  final Color characterCardBg;
  final Color characterCardBorder;
  final Color characterCardText;
  final Color characterCardSubtext;
  final Color characterCardIcon;
  final Color timerBg;
  final Color voteUnselectedBg;

  static const dark = AppColorsTheme(
    background: Color(0xFF0A1929),
    surface: Color(0xFF112D4E),
    surfaceLight: Color(0xFF1C4D8D),
    inputFill: Color(0xFF1C4D8D),
    textPrimary: Color(0xFFF9F7F7),
    textSecondary: Color(0xFFDBE2EF),
    textMuted: Color(0xFFBDE8F5),
    cardBg: Color(0xFF112D4E),
    cardBorder: Color(0xFF1C4D8D),
    buttonSecondary: Color(0xFF1C4D8D),
    hintCardBg: Color(0xFF112D4E),
    hintCardBorder: Color(0xFF1C4D8D),
    characterCardBg: Color(0xFF112D4E),
    characterCardBorder: Color(0xFF1C4D8D),
    characterCardText: Color(0xFFF9F7F7),
    characterCardSubtext: Color(0xFFDBE2EF),
    characterCardIcon: Color(0xFFDBE2EF),
    timerBg: Color(0xFF112D4E),
    voteUnselectedBg: Color(0xFF1C4D8D),
  );

  static const light = AppColorsTheme(
    background: Color(0xFFF9F7F7),
    surface: Color(0xFFDBE2EF),
    surfaceLight: Color(0xFF3F72AF),
    inputFill: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF112D4E),
    textSecondary: Color(0xFF3F72AF),
    textMuted: Color(0xFF3F72AF),
    cardBg: Color(0xFFDBE2EF),
    cardBorder: Color(0xFF3F72AF),
    buttonSecondary: Color(0xFFDBE2EF),
    hintCardBg: Color(0xFFDBE2EF),
    hintCardBorder: Color(0xFF3F72AF),
    characterCardBg: Color(0xFFDBE2EF),
    characterCardBorder: Color(0xFF3F72AF),
    characterCardText: Color(0xFF112D4E),
    characterCardSubtext: Color(0xFF3F72AF),
    characterCardIcon: Color(0xFF3F72AF),
    timerBg: Color(0xFFDBE2EF),
    voteUnselectedBg: Color(0xFFDBE2EF),
  );

  @override
  AppColorsTheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceLight,
    Color? inputFill,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? cardBg,
    Color? cardBorder,
    Color? buttonSecondary,
    Color? hintCardBg,
    Color? hintCardBorder,
    Color? characterCardBg,
    Color? characterCardBorder,
    Color? characterCardText,
    Color? characterCardSubtext,
    Color? characterCardIcon,
    Color? timerBg,
    Color? voteUnselectedBg,
  }) => AppColorsTheme(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceLight: surfaceLight ?? this.surfaceLight,
    inputFill: inputFill ?? this.inputFill,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    cardBg: cardBg ?? this.cardBg,
    cardBorder: cardBorder ?? this.cardBorder,
    buttonSecondary: buttonSecondary ?? this.buttonSecondary,
    hintCardBg: hintCardBg ?? this.hintCardBg,
    hintCardBorder: hintCardBorder ?? this.hintCardBorder,
    characterCardBg: characterCardBg ?? this.characterCardBg,
    characterCardBorder: characterCardBorder ?? this.characterCardBorder,
    characterCardText: characterCardText ?? this.characterCardText,
    characterCardSubtext: characterCardSubtext ?? this.characterCardSubtext,
    characterCardIcon: characterCardIcon ?? this.characterCardIcon,
    timerBg: timerBg ?? this.timerBg,
    voteUnselectedBg: voteUnselectedBg ?? this.voteUnselectedBg,
  );

  @override
  AppColorsTheme lerp(AppColorsTheme? other, double t) {
    if (other is! AppColorsTheme) return this;
    return AppColorsTheme(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceLight: Color.lerp(surfaceLight, other.surfaceLight, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      buttonSecondary: Color.lerp(buttonSecondary, other.buttonSecondary, t)!,
      hintCardBg: Color.lerp(hintCardBg, other.hintCardBg, t)!,
      hintCardBorder: Color.lerp(hintCardBorder, other.hintCardBorder, t)!,
      characterCardBg: Color.lerp(characterCardBg, other.characterCardBg, t)!,
      characterCardBorder: Color.lerp(
        characterCardBorder,
        other.characterCardBorder,
        t,
      )!,
      characterCardText: Color.lerp(
        characterCardText,
        other.characterCardText,
        t,
      )!,
      characterCardSubtext: Color.lerp(
        characterCardSubtext,
        other.characterCardSubtext,
        t,
      )!,
      characterCardIcon: Color.lerp(
        characterCardIcon,
        other.characterCardIcon,
        t,
      )!,
      timerBg: Color.lerp(timerBg, other.timerBg, t)!,
      voteUnselectedBg: Color.lerp(
        voteUnselectedBg,
        other.voteUnselectedBg,
        t,
      )!,
    );
  }
}

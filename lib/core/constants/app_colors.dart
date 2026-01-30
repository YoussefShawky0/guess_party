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
}

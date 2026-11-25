import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

/// Spacing scale in logical pixels.
class GameSpacing {
  const GameSpacing();

  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 24;
  final double xxl = 32;
}

/// Corner radii.
class GameRadius {
  const GameRadius();

  final double sm = 10;
  final double md = 16;
  final double lg = 24;
  final double pill = 999;
}

/// Chunky button geometry.
class GameButtonMetrics {
  const GameButtonMetrics();

  /// Height of the darker bottom edge while resting / pressed.
  final double depth = 5;
  final double pressedDepth = 1;
  final double minHeightLg = 56;
  final double minHeightMd = 48;
}

/// Animation timings and curves.
class GameMotion {
  const GameMotion();

  final Duration fast = const Duration(milliseconds: 120);
  final Duration base = const Duration(milliseconds: 220);
  final Duration slow = const Duration(milliseconds: 400);
  final Curve bounce = Curves.easeOutBack;
}

/// Colors of the trophy / reward chip.
class GameReward {
  const GameReward();

  final Color gold = AppColors.rewardGold;
  final Color edge = AppColors.rewardGoldEdge;
}

/// Design tokens of the game-style UI. Registered on both themes; read them
/// with [GameTokens.of].
@immutable
class GameTokens extends ThemeExtension<GameTokens> {
  const GameTokens({
    required this.primaryFace,
    required this.primaryEdge,
    required this.primaryOn,
    required this.secondaryFace,
    required this.secondaryEdge,
    required this.secondaryOn,
    required this.disabledFace,
    required this.disabledEdge,
    required this.disabledOn,
    required this.focusRing,
    required this.backgroundGlyph,
  });

  final Color primaryFace;
  final Color primaryEdge;
  final Color primaryOn;
  final Color secondaryFace;
  final Color secondaryEdge;
  final Color secondaryOn;
  final Color disabledFace;
  final Color disabledEdge;
  final Color disabledOn;
  final Color focusRing;

  /// Faint glyph color of the animated background (low alpha).
  final Color backgroundGlyph;

  final GameSpacing spacing = const GameSpacing();
  final GameRadius radius = const GameRadius();
  final GameButtonMetrics button = const GameButtonMetrics();
  final GameMotion motion = const GameMotion();
  final GameReward reward = const GameReward();

  static const dark = GameTokens(
    primaryFace: AppColors.buttonPrimary,
    primaryEdge: AppColors.buttonPrimaryEdge,
    primaryOn: AppColors.textPrimary,
    secondaryFace: AppColors.buttonSecondary,
    secondaryEdge: AppColors.buttonSecondaryEdge,
    secondaryOn: AppColors.textPrimary,
    disabledFace: Color(0xFF1B3550),
    disabledEdge: AppColors.buttonDisabledEdge,
    disabledOn: Color(0xFF7F93A8),
    focusRing: AppColors.textMuted,
    backgroundGlyph: Color(0x14BDE8F5),
  );

  static const light = GameTokens(
    primaryFace: AppColors.primary,
    primaryEdge: AppColors.buttonPrimaryEdge,
    primaryOn: Colors.white,
    secondaryFace: AppColors.secondaryLight,
    secondaryEdge: AppColors.buttonSecondaryEdgeLight,
    secondaryOn: AppColors.textDark,
    disabledFace: Color(0xFFE3E7EF),
    disabledEdge: Color(0xFFC3CAD8),
    disabledOn: Color(0xFF8A94A6),
    focusRing: AppColors.primaryDark,
    backgroundGlyph: Color(0x193F72AF),
  );

  static GameTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<GameTokens>() ??
        (theme.brightness == Brightness.dark ? dark : light);
  }

  @override
  GameTokens copyWith({
    Color? primaryFace,
    Color? primaryEdge,
    Color? primaryOn,
    Color? secondaryFace,
    Color? secondaryEdge,
    Color? secondaryOn,
    Color? disabledFace,
    Color? disabledEdge,
    Color? disabledOn,
    Color? focusRing,
    Color? backgroundGlyph,
  }) => GameTokens(
    primaryFace: primaryFace ?? this.primaryFace,
    primaryEdge: primaryEdge ?? this.primaryEdge,
    primaryOn: primaryOn ?? this.primaryOn,
    secondaryFace: secondaryFace ?? this.secondaryFace,
    secondaryEdge: secondaryEdge ?? this.secondaryEdge,
    secondaryOn: secondaryOn ?? this.secondaryOn,
    disabledFace: disabledFace ?? this.disabledFace,
    disabledEdge: disabledEdge ?? this.disabledEdge,
    disabledOn: disabledOn ?? this.disabledOn,
    focusRing: focusRing ?? this.focusRing,
    backgroundGlyph: backgroundGlyph ?? this.backgroundGlyph,
  );

  @override
  GameTokens lerp(GameTokens? other, double t) {
    if (other is! GameTokens) return this;
    return GameTokens(
      primaryFace: Color.lerp(primaryFace, other.primaryFace, t)!,
      primaryEdge: Color.lerp(primaryEdge, other.primaryEdge, t)!,
      primaryOn: Color.lerp(primaryOn, other.primaryOn, t)!,
      secondaryFace: Color.lerp(secondaryFace, other.secondaryFace, t)!,
      secondaryEdge: Color.lerp(secondaryEdge, other.secondaryEdge, t)!,
      secondaryOn: Color.lerp(secondaryOn, other.secondaryOn, t)!,
      disabledFace: Color.lerp(disabledFace, other.disabledFace, t)!,
      disabledEdge: Color.lerp(disabledEdge, other.disabledEdge, t)!,
      disabledOn: Color.lerp(disabledOn, other.disabledOn, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      backgroundGlyph: Color.lerp(backgroundGlyph, other.backgroundGlyph, t)!,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

/// The username's initial in a circle. The color comes from a fixed palette
/// and only depends on the name, so a player always looks the same.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.showDot = false,
  });

  final String name;
  final double size;

  /// Warning-yellow dot (for example "account not secured yet").
  final bool showDot;

  /// Stable across runs and platforms (unlike `String.hashCode`).
  static int stableHash(String value) {
    var hash = 0;
    for (final unit in value.trim().toLowerCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }

  static Color colorFor(String name) =>
      AppColors.avatarColors[stableHash(name) % AppColors.avatarColors.length];

  static String initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(name);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : AppColors.textDark;
    final dot = size * 0.3;

    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    initialOf(name),
                    style: TextStyle(
                      color: onColor,
                      fontSize: size * 0.45,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            if (showDot)
              PositionedDirectional(
                end: -dot * 0.1,
                bottom: -dot * 0.1,
                child: Container(
                  key: const Key('player-avatar-dot'),
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Round 44 px icon button. [tooltip] doubles as the semantic label, so it is
/// required.
class GameIconButton extends StatelessWidget {
  const GameIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        excludeSemantics: true,
        onTap: onPressed,
        child: Material(
          color: scheme.surface,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: IconTheme.merge(
                  data: IconThemeData(color: fg, size: 18),
                  child: icon,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

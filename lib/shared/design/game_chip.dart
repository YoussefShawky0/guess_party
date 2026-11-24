import 'package:flutter/material.dart';
import 'package:guess_party/core/design/game_tokens.dart';

/// A pill with an optional icon and label. Use for compact top-bar actions
/// (profile, trophy count).
///
/// Give [semanticLabel] whenever [label] is missing or not self-explanatory.
class GameChip extends StatelessWidget {
  const GameChip({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.semanticLabel,
    this.background,
    this.foreground,
    this.edge,
  }) : assert(icon != null || label != null, 'A chip needs an icon or label');

  final VoidCallback onTap;
  final Widget? icon;
  final String? label;
  final String? semanticLabel;
  final Color? background;
  final Color? foreground;

  /// Darker bottom edge; omitted for a flat chip.
  final Color? edge;

  @override
  Widget build(BuildContext context) {
    final tokens = GameTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurface;
    final bg = background ?? scheme.surface;
    final shape = StadiumBorder(
      side: BorderSide(color: fg.withValues(alpha: 0.12)),
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      onTap: onTap,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: shape,
          color: bg,
          shadows: edge == null
              ? null
              : [BoxShadow(color: edge!, offset: const Offset(0, 3))],
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: tokens.spacing.md,
                  vertical: tokens.spacing.xs,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      IconTheme.merge(
                        data: IconThemeData(color: fg, size: 18),
                        child: icon!,
                      ),
                    if (icon != null && label != null)
                      SizedBox(width: tokens.spacing.sm),
                    if (label != null)
                      Flexible(
                        child: Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: fg, fontSize: 16),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

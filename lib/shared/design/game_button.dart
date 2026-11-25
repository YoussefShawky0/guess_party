import 'dart:async';

import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';
import 'package:guess_party/features/game/presentation/feedback/game_feedback_listener.dart'
    show gameFeedbackOf;

/// `reward` is gold, for the one celebratory action on a screen (for example
/// "View final leaderboard"). Use it instead of `primary`, never next to it.
enum GameButtonVariant { primary, secondary, reward }

enum GameButtonSize { lg, md }

/// Chunky game-style button with a darker bottom edge.
///
/// Fills the available width. [GameButtonSize] only sets a **minimum**
/// height: the label wraps and the button grows with the text scale.
/// `onPressed == null` renders the disabled look. While [isLoading] the label
/// is replaced by a spinner and taps are ignored.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = GameButtonVariant.primary,
    this.size = GameButtonSize.lg,
    this.isLoading = false,
    this.semanticHint,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final GameButtonVariant variant;
  final GameButtonSize size;
  final bool isLoading;

  /// Extra screen-reader hint, read after the label.
  final String? semanticHint;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _pressed = false;
  bool _focused = false;

  bool get _interactive => widget.onPressed != null && !widget.isLoading;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    if (!_interactive) return;
    unawaited(gameFeedbackOf(context).tapHaptic());
    widget.onPressed!();
  }

  @override
  void didUpdateWidget(GameButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GameTokens.of(context);
    final interactive = _interactive;
    final disabled = !widget.isLoading && widget.onPressed == null;
    final (Color face, Color edge, Color on) = disabled
        ? (tokens.disabledFace, tokens.disabledEdge, tokens.disabledOn)
        : switch (widget.variant) {
            GameButtonVariant.primary => (
              tokens.primaryFace,
              tokens.primaryEdge,
              tokens.primaryOn,
            ),
            GameButtonVariant.secondary => (
              tokens.secondaryFace,
              tokens.secondaryEdge,
              tokens.secondaryOn,
            ),
            GameButtonVariant.reward => (
              tokens.reward.gold,
              tokens.reward.edge,
              AppColors.textDark,
            ),
          };

    final isLg = widget.size == GameButtonSize.lg;
    final depth = tokens.button.depth;
    final shown = _pressed && interactive ? tokens.button.pressedDepth : depth;
    final radius = BorderRadius.circular(tokens.radius.md);
    final textStyle =
        (Theme.of(context).textTheme.labelLarge ?? const TextStyle()).copyWith(
          color: on,
          fontSize: isLg ? 20 : 16,
          height: 1.15,
        );

    final content = widget.isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 3, color: on),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                IconTheme.merge(
                  data: IconThemeData(color: on, size: isLg ? 22 : 18),
                  child: widget.icon!,
                ),
                SizedBox(width: tokens.spacing.md),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: textStyle,
                ),
              ),
            ],
          );

    return Semantics(
      container: true,
      button: true,
      enabled: interactive,
      label: widget.label,
      hint: widget.semanticHint,
      excludeSemantics: true,
      onTap: interactive ? _activate : null,
      child: FocusableActionDetector(
        enabled: interactive,
        mouseCursor: interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: interactive ? (_) => _setPressed(true) : null,
          onTapUp: interactive ? (_) => _setPressed(false) : null,
          onTapCancel: interactive ? () => _setPressed(false) : null,
          onTap: interactive ? _activate : null,
          child: Padding(
            // Reserves the resting edge so the layout never jumps on press.
            padding: EdgeInsets.only(bottom: depth),
            child: AnimatedContainer(
              key: const Key('game-button-face'),
              duration: tokens.motion.fast,
              curve: Curves.easeOut,
              transform: Matrix4.translationValues(0, depth - shown, 0),
              constraints: BoxConstraints(
                minHeight: isLg
                    ? tokens.button.minHeightLg
                    : tokens.button.minHeightMd,
              ),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: tokens.spacing.xl,
                vertical: tokens.spacing.sm,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: face,
                borderRadius: radius,
                boxShadow: [BoxShadow(color: edge, offset: Offset(0, shown))],
              ),
              foregroundDecoration: _focused
                  ? BoxDecoration(
                      borderRadius: radius,
                      border: Border.all(color: tokens.focusRing, width: 3),
                    )
                  : null,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

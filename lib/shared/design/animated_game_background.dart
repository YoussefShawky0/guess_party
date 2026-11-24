import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/design/game_tokens.dart';

/// Faint question-mark / eye / mask glyphs drifting upward behind [child].
///
/// Cost control:
/// - one [AnimationController] (30 s loop) drives a [CustomPainter] through
///   `repaint:`, so nothing rebuilds per frame;
/// - the glyph [TextPainter]s are laid out once and cached;
/// - it is a single frame when the platform asks to reduce animations, and it
///   stops while the ticker mode is off, the app is not resumed, or no pointer
///   input arrived for [idleTimeout].
///
/// Do not put it behind gameplay rounds.
class AnimatedGameBackground extends StatefulWidget {
  const AnimatedGameBackground({
    super.key,
    required this.child,
    this.idleTimeout = const Duration(seconds: 60),
  });

  final Widget child;
  final Duration idleTimeout;

  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _GlyphSpec {
  const _GlyphSpec(
    this.icon,
    this.x,
    this.phase,
    this.size,
    this.speed,
    this.angle,
  );

  final FaIconData icon;

  /// Horizontal position, 0..1 of the width.
  final double x;

  /// Start offset in the loop, 0..1.
  final double phase;
  final double size;

  /// Whole number of passes per loop, so the loop wraps seamlessly.
  final int speed;
  final double angle;
}

const _specs = <_GlyphSpec>[
  _GlyphSpec(FontAwesomeIcons.circleQuestion, 0.08, 0.00, 30, 1, -0.2),
  _GlyphSpec(FontAwesomeIcons.eye, 0.24, 0.35, 26, 1, 0.15),
  _GlyphSpec(FontAwesomeIcons.masksTheater, 0.41, 0.70, 32, 1, -0.1),
  _GlyphSpec(FontAwesomeIcons.userSecret, 0.58, 0.15, 30, 1, 0.2),
  _GlyphSpec(FontAwesomeIcons.circleQuestion, 0.74, 0.55, 24, 2, 0.3),
  _GlyphSpec(FontAwesomeIcons.eye, 0.90, 0.90, 28, 1, -0.25),
  _GlyphSpec(FontAwesomeIcons.userSecret, 0.15, 0.60, 22, 2, 0.1),
  _GlyphSpec(FontAwesomeIcons.masksTheater, 0.32, 0.10, 24, 2, -0.3),
  _GlyphSpec(FontAwesomeIcons.circleQuestion, 0.50, 0.40, 34, 1, 0.05),
  _GlyphSpec(FontAwesomeIcons.eye, 0.66, 0.80, 22, 2, 0.2),
  _GlyphSpec(FontAwesomeIcons.userSecret, 0.83, 0.25, 26, 1, -0.15),
  _GlyphSpec(FontAwesomeIcons.masksTheater, 0.95, 0.50, 20, 2, 0.25),
  _GlyphSpec(FontAwesomeIcons.circleQuestion, 0.03, 0.85, 22, 1, 0.3),
  _GlyphSpec(FontAwesomeIcons.eye, 0.48, 0.95, 20, 2, -0.05),
];

class _Glyph {
  _Glyph(this.spec, this.painter);

  final _GlyphSpec spec;
  final TextPainter painter;
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 30),
    value: 0.3,
  );

  List<_Glyph> _glyphs = const [];
  Color? _glyphColor;
  Timer? _idleTimer;
  bool _reduceMotion = false;
  bool _resumed = true;
  bool _idle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _resumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final color = GameTokens.of(context).backgroundGlyph;
    if (color != _glyphColor) {
      _glyphColor = color;
      _disposeGlyphs();
      _glyphs = [for (final spec in _specs) _layout(spec, color)];
    }
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  _Glyph _layout(_GlyphSpec spec, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(spec.icon.codePoint),
        style: TextStyle(
          fontSize: spec.size,
          fontFamily: spec.icon.fontFamily,
          package: spec.icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return _Glyph(spec, painter);
  }

  void _disposeGlyphs() {
    for (final glyph in _glyphs) {
      glyph.painter.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  bool get _shouldRun => !_reduceMotion && !_idle && _resumed;

  void _sync() {
    if (_shouldRun) {
      if (!_controller.isAnimating) _controller.repeat();
      _idleTimer ??= Timer(widget.idleTimeout, _onIdle);
    } else {
      if (_controller.isAnimating) _controller.stop();
      _idleTimer?.cancel();
      _idleTimer = null;
    }
  }

  void _onIdle() {
    _idleTimer = null;
    _idle = true;
    _sync();
  }

  void _onPointer(PointerEvent event) {
    _idleTimer?.cancel();
    _idleTimer = null;
    _idle = false;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    _controller.dispose();
    _disposeGlyphs();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointer,
      onPointerMove: _onPointer,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GlyphPainter(_controller, _glyphs),
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.animation, this.glyphs) : super(repaint: animation);

  final Animation<double> animation;
  final List<_Glyph> glyphs;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    for (final glyph in glyphs) {
      final spec = glyph.spec;
      final run = (t * spec.speed + spec.phase) % 1.0;
      final span = size.height + spec.size * 2;
      final y = size.height + spec.size - run * span;
      final tp = glyph.painter;
      canvas.save();
      canvas.translate(spec.x * size.width, y);
      canvas.rotate(spec.angle + math.sin(run * math.pi * 2) * 0.05);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.glyphs != glyphs;
}

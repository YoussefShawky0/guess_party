import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';
import 'package:guess_party/l10n/l10n.dart';

/// The three characters with one shared gentle bob (the impostor is
/// phase-offset), and the game title below. Static under reduce-motion.
class HomeHero extends StatefulWidget {
  const HomeHero({super.key, required this.isTablet});

  final bool isTablet;

  @override
  State<HomeHero> createState() => _HomeHeroState();
}

class _HomeHeroState extends State<HomeHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = GameTokens.of(context);
    final isTablet = widget.isTablet;
    final width = isTablet ? 80.0 : 60.0;
    final height = isTablet ? 100.0 : 75.0;
    final gap = SizedBox(width: isTablet ? 16 : 12);

    Widget character(double phase, {bool impostor = false}) {
      final image = Image.asset(
        impostor ? 'assets/images/Imposter.png' : 'assets/images/Innocent.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
      return _Bob(
        animation: _controller,
        phase: phase,
        child: impostor
            ? Container(
                padding: EdgeInsetsDirectional.all(tokens.spacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(tokens.radius.md),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: image,
              )
            : image,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            character(0),
            gap,
            character(0.25, impostor: true),
            gap,
            character(0),
          ],
        ),
        SizedBox(height: tokens.spacing.xl),
        Text(
          context.l10n.homeTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppColors.of(context).textPrimary,
          ),
        ),
      ],
    );
  }
}

class _Bob extends StatelessWidget {
  const _Bob({
    required this.animation,
    required this.phase,
    required this.child,
  });

  final Animation<double> animation;
  final double phase;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(
          0,
          -math.sin((animation.value + phase) * math.pi * 2) * 5,
        ),
        child: child,
      ),
    );
  }
}

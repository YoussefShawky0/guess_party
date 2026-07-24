import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF091929),
                    Color(0xFF061322),
                    Color(0xFF030A11),
                  ],
                  stops: [0, 0.58, 1],
                ),
              ),
            ),
          ),
          const PositionedDirectional(
            start: -155,
            top: -120,
            child: _AmbientGlow(
              size: 420,
              color: AppColors.primary,
              opacity: 0.18,
            ),
          ),
          const PositionedDirectional(
            end: -130,
            top: 90,
            child: _AmbientGlow(
              size: 300,
              color: AppColors.error,
              opacity: 0.12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

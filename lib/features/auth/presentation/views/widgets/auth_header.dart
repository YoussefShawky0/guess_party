import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'auth_brand_accent.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final artworkWidth = isTablet ? 360.0 : 280.0;
    final artworkHeight = artworkWidth * 281 / 614;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: artworkWidth,
          height: artworkHeight,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(
                bottom: 6,
                child: Container(
                  width: artworkWidth * 0.78,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.38),
                        blurRadius: 18,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Image.asset(
                'assets/images/Figures.png',
                key: const Key('auth-figures'),
                width: artworkWidth,
                height: artworkHeight,
                fit: BoxFit.contain,
                semanticLabel: context.l10n.appName,
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(
            key: const Key('auth-brand-title'),
            TextSpan(
              children: [
                TextSpan(
                  text: 'Guess ',
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
                const TextSpan(
                  text: 'Party',
                  style: TextStyle(color: AppColors.primaryLight),
                ),
              ],
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 46 : 38,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
        ),
        SizedBox(height: isTablet ? 10 : 8),
        Text(
          context.l10n.findTheImposterOwnTheRoom,
          style: TextStyle(
            fontSize: isTablet ? 17 : 15,
            height: 1.45,
            letterSpacing: 0.15,
            color: AppColors.of(context).textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isTablet ? 18 : 14),
        const AuthBrandAccent(),
      ],
    );
  }
}

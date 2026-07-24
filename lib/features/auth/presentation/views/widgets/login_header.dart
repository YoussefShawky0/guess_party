import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({required this.title, this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final artworkWidth = isTablet ? 300.0 : 220.0;
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
                bottom: 4,
                child: Container(
                  width: artworkWidth * 0.76,
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
              Image.asset(
                'assets/images/Figures.png',
                key: const Key('login-figures'),
                width: artworkWidth,
                height: artworkHeight,
                fit: BoxFit.contain,
                semanticLabel: context.l10n.appName,
              ),
            ],
          ),
        ),
        SizedBox(height: isTablet ? 22 : 18),
        Text(
          title,
          key: const Key('login-header-title'),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isTablet ? 36 : 32,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.of(context).textPrimary,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 10),
          Text(
            description!,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.4,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

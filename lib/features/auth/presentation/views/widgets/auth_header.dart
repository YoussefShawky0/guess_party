import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        Image.asset(
          'assets/images/Figures.png',
          width: isTablet ? 240 : 180,
          height: isTablet ? 170 : 130,
          fit: BoxFit.contain,
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Text(
          'Guess Party',
          style: TextStyle(
            fontSize: isTablet ? 48 : 40,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isTablet ? 8 : 6),
        Text(
          'Find the Imposter',
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

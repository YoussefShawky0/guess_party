import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class WelcomeSection extends StatelessWidget {
  final String username;
  final bool isTablet;

  const WelcomeSection({
    super.key,
    required this.username,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 28 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, AppColors.surface.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Character Images Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Innocent Character
              Image.asset(
                'assets/images/Innocent.png',
                width: isTablet ? 80 : 60,
                height: isTablet ? 100 : 75,
                fit: BoxFit.contain,
              ),
              SizedBox(width: isTablet ? 16 : 12),
              // Imposter Character (highlighted)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Image.asset(
                  'assets/images/Imposter.png',
                  width: isTablet ? 80 : 60,
                  height: isTablet ? 100 : 75,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              // Innocent Character
              Image.asset(
                'assets/images/Innocent.png',
                width: isTablet ? 80 : 60,
                height: isTablet ? 100 : 75,
                fit: BoxFit.contain,
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          Text(
            'Welcome, $username!',
            style: TextStyle(
              fontSize: isTablet ? 28 : 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 8 : 6),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 16,
              vertical: isTablet ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Ready to find the Imposter?',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;

  const ErrorScreen({
    super.key,
    required this.message,
    this.onRetry,
    this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 32 : 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: AppColors.error,
                size: isTablet ? 80 : 64,
              ),
              SizedBox(height: isTablet ? 32 : 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 40 : 32),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                      vertical: isTablet ? 16 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    context.l10n.retry,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (onRetry != null && onGoBack != null)
                SizedBox(height: isTablet ? 16 : 12),
              if (onGoBack != null)
                TextButton(
                  onPressed: onGoBack,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 32 : 24,
                      vertical: isTablet ? 16 : 14,
                    ),
                  ),
                  child: Text(
                    context.l10n.goBack,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: AppColors.of(context).textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

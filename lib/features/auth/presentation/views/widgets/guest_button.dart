import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

class GuestButton extends StatelessWidget {
  const GuestButton({this.onPressed, this.isLoading = false, super.key});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final isEnabled = onPressed != null && !isLoading;

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: context.l10n.startPlaying,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isEnabled
                ? const [Color(0xFF35659B), AppColors.primary]
                : const [AppColors.buttonDisabled, AppColors.buttonDisabled],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF062A4D).withValues(alpha: 0.42),
                    offset: const Offset(0, 10),
                    blurRadius: 22,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('guest-start-button'),
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: isTablet ? 64 : 60,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 16, end: 14),
                child: isLoading
                    ? Center(
                        child: SizedBox.square(
                          dimension: isTablet ? 26 : 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          const SizedBox.square(dimension: 34),
                          Expanded(
                            child: Text(
                              context.l10n.startPlaying,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.of(context).textPrimary,
                                fontSize: isTablet ? 19 : 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
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

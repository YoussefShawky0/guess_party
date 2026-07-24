import 'package:flutter/material.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'guest_button.dart';
import 'username_field.dart';

class GuestSignInForm extends StatelessWidget {
  const GuestSignInForm({
    required this.usernameController,
    required this.isLoading,
    required this.onStartPlaying,
    super.key,
  });

  final TextEditingController usernameController;
  final bool isLoading;
  final VoidCallback onStartPlaying;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.playAsGuest.toUpperCase(),
          style: TextStyle(
            color: AppColors.primaryLight,
            fontSize: isTablet ? 13 : 11,
            height: 1.45,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 14),
        UsernameField(controller: usernameController, enabled: !isLoading),
        const SizedBox(height: 14),
        GuestButton(
          onPressed: isLoading ? null : onStartPlaying,
          isLoading: isLoading,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.noAccountRequired,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF7492AD),
            fontSize: isTablet ? 14 : 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

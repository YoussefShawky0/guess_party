import 'package:flutter/material.dart';
import 'package:guess_party/l10n/l10n.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({required this.onLogin, super.key});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    return TextButton(
      key: const Key('auth-login-action'),
      onPressed: onLogin,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF60A0DD),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 5,
        children: [
          Text(
            context.l10n.alreadyHaveAccountPrompt,
            style: TextStyle(
              color: const Color(0xFF83A1BC),
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            context.l10n.login,
            style: TextStyle(
              color: const Color(0xFF60A0DD),
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

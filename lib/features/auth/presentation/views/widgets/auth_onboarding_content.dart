import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_background.dart';
import 'auth_footer.dart';
import 'auth_header.dart';
import 'guest_sign_in_form.dart';
import 'session_ended_banner.dart';

class AuthOnboardingContent extends StatelessWidget {
  const AuthOnboardingContent({
    required this.formKey,
    required this.usernameController,
    required this.isLoading,
    required this.sessionEnded,
    required this.onStartPlaying,
    required this.onLogin,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final bool isLoading;
  final bool sessionEnded;
  final VoidCallback onStartPlaying;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: AuthBackground()),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth >= 600;
              final horizontalPadding = isTablet ? 32.0 : 24.0;
              final verticalPadding = isTablet ? 32.0 : 24.0;
              final minimumHeight = math.max(
                0.0,
                constraints.maxHeight - (verticalPadding * 2),
              );

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 440 : 312,
                      minHeight: minimumHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AuthHeader(),
                            if (sessionEnded) ...[
                              SizedBox(height: isTablet ? 28 : 22),
                              const SessionEndedBanner(),
                            ],
                            SizedBox(height: isTablet ? 48 : 36),
                            GuestSignInForm(
                              usernameController: usernameController,
                              isLoading: isLoading,
                              onStartPlaying: onStartPlaying,
                            ),
                            SizedBox(height: isTablet ? 54 : 42),
                            AuthFooter(onLogin: onLogin),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

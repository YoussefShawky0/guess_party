import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/error_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'widgets/auth_onboarding_content.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({this.sessionEnded = false, super.key});

  final bool sessionEnded;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthCubit>(),
      child: AuthView(sessionEnded: sessionEnded),
    );
  }
}

class AuthView extends StatefulWidget {
  const AuthView({this.sessionEnded = false, super.key});

  final bool sessionEnded;

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _usernameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _handleGuestSignIn() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(_usernameController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            final router = GoRouter.of(context);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (!mounted) return;
              router.go(AppRoutes.home);
            });
          } else if (state is AuthError) {
            ErrorSnackBar.show(context, state.message);
          }
        },
        builder: (context, state) {
          return AuthOnboardingContent(
            formKey: _formKey,
            usernameController: _usernameController,
            isLoading: state is AuthLoading,
            sessionEnded: widget.sessionEnded,
            onStartPlaying: _handleGuestSignIn,
            onLogin: () => context.push(AppRoutes.login),
          );
        },
      ),
    );
  }
}

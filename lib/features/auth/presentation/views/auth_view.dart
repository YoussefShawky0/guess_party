import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/error_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'widgets/auth_header.dart';
import 'widgets/guest_button.dart';
import 'widgets/username_field.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AuthCubit>(),
      child: const AuthView(),
    );
  }
}

class AuthView extends StatefulWidget {
  const AuthView({super.key});

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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ErrorSnackBar.showSuccess(context, 'أهلاً بك! 👋');
            Future.delayed(const Duration(milliseconds: 500), () {
              context.go('/home');
            });
          } else if (state is AuthError) {
            ErrorSnackBar.show(context, state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? size.width * 0.2 : 24,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AuthHeader(),
                      SizedBox(height: isTablet ? 80 : 60),
                      UsernameField(
                        controller: _usernameController,
                        enabled: state is! AuthLoading,
                      ),
                      const SizedBox(height: 32),
                      GuestButton(
                        onPressed: state is AuthLoading
                            ? null
                            : _handleGuestSignIn,
                        isLoading: state is AuthLoading,
                      ),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () {
                          context.push('/login');
                        },
                        child: Text(
                          'Already have an account? Login',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: isTablet ? 16 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

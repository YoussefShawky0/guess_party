import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_routes.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<AuthCubit>(),
    child: const ResetPasswordView(),
  );
}

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recoveryIsValid = di
        .sl<AuthSessionService>()
        .hasPasswordRecoverySession;
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a new password')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: recoveryIsValid
                  ? BlocConsumer<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthError) {
                          ErrorSnackBar.show(context, state.message);
                        } else if (state is AuthPasswordUpdated) {
                          context.go(AppRoutes.login);
                        }
                      },
                      builder: (context, state) => Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Enter a new password for your verified account.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: const InputDecoration(
                                labelText: 'New password',
                              ),
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmationController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm password',
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'Passwords do not match'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: state is AuthLoading
                                  ? null
                                  : () {
                                      if (_formKey.currentState!.validate()) {
                                        context
                                            .read<AuthCubit>()
                                            .updateRecoveredPassword(
                                              _passwordController.text,
                                            );
                                      }
                                    },
                              child: state is AuthLoading
                                  ? const CircularProgressIndicator()
                                  : const Text('Update password'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_off, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'This password recovery link is no longer valid.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: const Text('Return to login'),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

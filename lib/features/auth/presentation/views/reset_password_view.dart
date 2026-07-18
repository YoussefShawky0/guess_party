import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/l10n/l10n.dart';

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
      appBar: AppBar(title: Text(context.l10n.chooseNewPassword)),
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
                            Text(
                              context.l10n.enterNewPassword,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              autofillHints: const [AutofillHints.newPassword],
                              decoration: InputDecoration(
                                labelText: context.l10n.newPassword,
                              ),
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmationController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: context.l10n.confirmPassword,
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? context.l10n.passwordsDoNotMatch
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
                                  : Text(context.l10n.updatePassword),
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
                        Text(
                          context.l10n.recoveryLinkExpired,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go(AppRoutes.login),
                          child: Text(context.l10n.returnToLogin),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/l10n/l10n.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

enum _AuthFormMode { signIn, signUp, legacy }

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => di.sl<AuthCubit>(), child: const LoginView());
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailOrUsernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _AuthFormMode _mode = _AuthFormMode.signIn;

  @override
  void dispose() {
    _emailOrUsernameController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(_AuthFormMode mode) {
    setState(() {
      _mode = mode;
      _formKey.currentState?.reset();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    final identifier = _emailOrUsernameController.text.trim();
    final password = _passwordController.text;
    switch (_mode) {
      case _AuthFormMode.signIn:
        cubit.signInWithPassword(identifier, password);
      case _AuthFormMode.signUp:
        cubit.signUp(identifier, _displayNameController.text.trim(), password);
      case _AuthFormMode.legacy:
        cubit.signInLegacyWithPassword(identifier, password);
    }
  }

  Future<void> _showPasswordResetDialog() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.resetPassword),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: dialogContext.l10n.email),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (Validators.email(value) == null) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Text(dialogContext.l10n.sendLink),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || email == null) return;
    context.read<AuthCubit>().requestPasswordReset(email);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isSignUp = _mode == _AuthFormMode.signUp;
    final isLegacy = _mode == _AuthFormMode.legacy;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            context.go(AppRoutes.home);
          } else if (state is AuthError) {
            ErrorSnackBar.show(context, state.message);
          } else if (state is AuthMessage) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) => SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? size.width * 0.2 : 24,
                vertical: 24,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/Figures.png',
                      width: isTablet ? 200 : 150,
                      height: isTablet ? 140 : 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isSignUp
                          ? context.l10n.createAccount
                          : isLegacy
                          ? context.l10n.legacyAccount
                          : context.l10n.welcomeBack,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 36 : 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    if (isLegacy) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.legacyAccountHelp,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    ],
                    SizedBox(height: isTablet ? 40 : 32),
                    if (isSignUp) ...[
                      _AuthTextField(
                        controller: _displayNameController,
                        label: context.l10n.displayName,
                        icon: Icons.badge_outlined,
                        validator: Validators.username,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _AuthTextField(
                      controller: _emailOrUsernameController,
                      label: isLegacy
                          ? context.l10n.legacyUsername
                          : context.l10n.email,
                      icon: isLegacy
                          ? Icons.person_outline
                          : Icons.email_outlined,
                      keyboardType: isLegacy
                          ? TextInputType.text
                          : TextInputType.emailAddress,
                      autofillHints: isLegacy
                          ? const [AutofillHints.username]
                          : const [AutofillHints.email],
                      validator: isLegacy
                          ? Validators.username
                          : Validators.email,
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _passwordController,
                      label: context.l10n.password,
                      icon: Icons.lock_outline,
                      obscureText: true,
                      autofillHints: [
                        isSignUp
                            ? AutofillHints.newPassword
                            : AutofillHints.password,
                      ],
                      validator: Validators.password,
                    ),
                    if (_mode == _AuthFormMode.signIn)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: state is AuthLoading
                              ? null
                              : _showPasswordResetDialog,
                          child: Text(context.l10n.forgotPassword),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: state is AuthLoading ? null : _submit,
                      child: state is AuthLoading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isSignUp
                                  ? context.l10n.createAccount
                                  : isLegacy
                                  ? context.l10n.legacyLogin
                                  : context.l10n.login,
                            ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () => _setMode(
                              isSignUp
                                  ? _AuthFormMode.signIn
                                  : _AuthFormMode.signUp,
                            ),
                      child: Text(
                        isSignUp
                            ? context.l10n.alreadyHaveAccount
                            : context.l10n.createVerifiedAccount,
                      ),
                    ),
                    TextButton(
                      onPressed: state is AuthLoading
                          ? null
                          : () => _setMode(
                              isLegacy
                                  ? _AuthFormMode.signIn
                                  : _AuthFormMode.legacy,
                            ),
                      child: Text(
                        isLegacy
                            ? context.l10n.backToEmailLogin
                            : context.l10n.useLegacyAccount,
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

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    autofillHints: autofillHints,
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppColors.of(context).surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

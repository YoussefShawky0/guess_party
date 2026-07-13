import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/error_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class AccountUpgradeScreen extends StatelessWidget {
  const AccountUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => di.sl<AuthCubit>(),
    child: const AccountUpgradeView(),
  );
}

class AccountUpgradeView extends StatefulWidget {
  const AccountUpgradeView({super.key});

  @override
  State<AccountUpgradeView> createState() => _AccountUpgradeViewState();
}

class _AccountUpgradeViewState extends State<AccountUpgradeView> {
  final _emailController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _upgradeFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  bool _upgradeRequested = false;

  @override
  void initState() {
    super.initState();
    final session = di.sl<AuthSessionService>();
    _displayNameController.text = session.currentUsername;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = di.sl<AuthSessionService>();
    final canUpgrade = session.isAnonymous || session.isLegacyAccount;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure your account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthError) {
                    ErrorSnackBar.show(context, state.message);
                  } else if (state is AuthUpgradePending) {
                    setState(() => _upgradeRequested = true);
                  } else if (state is AuthMessage) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) {
                  if (!canUpgrade && !_upgradeRequested) {
                    return const Text(
                      'This account already uses a real email.',
                      textAlign: TextAlign.center,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Link a real email to preserve this account and its user ID. Accounts are never merged automatically.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _upgradeFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _displayNameController,
                              decoration: const InputDecoration(
                                labelText: 'Display name',
                              ),
                              validator: Validators.username,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'Real email',
                              ),
                              validator: Validators.email,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: state is AuthLoading || _upgradeRequested
                            ? null
                            : () {
                                if (_upgradeFormKey.currentState!.validate()) {
                                  context.read<AuthCubit>().beginAccountUpgrade(
                                    _emailController.text,
                                    _displayNameController.text,
                                  );
                                }
                              },
                        child: const Text('Send verification email'),
                      ),
                      if (_upgradeRequested) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Check your inbox and open the verification link. Return here afterward to set a password if needed.',
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: _passwordFormKey,
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Account password',
                            ),
                            validator: Validators.password,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () {
                                  if (_passwordFormKey.currentState!
                                      .validate()) {
                                    context
                                        .read<AuthCubit>()
                                        .setVerifiedAccountPassword(
                                          _passwordController.text,
                                        );
                                  }
                                },
                          child: const Text('Complete verified upgrade'),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

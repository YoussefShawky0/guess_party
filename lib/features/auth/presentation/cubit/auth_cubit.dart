import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/usecases/begin_account_upgrade.dart';
import '../../domain/usecases/request_password_reset.dart';
import '../../domain/usecases/set_verified_account_password.dart';
import '../../domain/usecases/sign_in_guest.dart';
import '../../domain/usecases/sign_in_legacy_with_password.dart';
import '../../domain/usecases/sign_in_with_password.dart';
import '../../domain/usecases/sign_up_with_password.dart';
import '../../domain/usecases/update_recovered_password.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInGuest signInGuest;
  final SignUpWithPassword signUpWithPassword;
  final SignInWithPassword signInWithPasswordUseCase;
  final SignInLegacyWithPassword signInLegacyWithPasswordUseCase;
  final RequestPasswordReset requestPasswordResetUseCase;
  final BeginAccountUpgrade beginAccountUpgradeUseCase;
  final SetVerifiedAccountPassword setVerifiedAccountPasswordUseCase;
  final UpdateRecoveredPassword updateRecoveredPasswordUseCase;

  AuthCubit({
    required this.signInGuest,
    required this.signUpWithPassword,
    required this.signInWithPasswordUseCase,
    required this.signInLegacyWithPasswordUseCase,
    required this.requestPasswordResetUseCase,
    required this.beginAccountUpgradeUseCase,
    required this.setVerifiedAccountPasswordUseCase,
    required this.updateRecoveredPasswordUseCase,
  }) : super(AuthInitial());

  Future<void> signIn(String username) async {
    emit(AuthLoading());

    final result = await signInGuest(username);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signUp(String email, String displayName, String password) async {
    emit(AuthLoading());

    final result = await signUpWithPassword(
      email: email,
      displayName: displayName,
      password: password,
    );

    result.fold(
      (failure) => emit(
        failure is EmailVerificationRequiredFailure
            ? AuthMessage(failure.message)
            : AuthError(failure.message),
      ),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signInWithPassword(String email, String password) async {
    emit(AuthLoading());

    final result = await signInWithPasswordUseCase(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signInLegacyWithPassword(
    String username,
    String password,
  ) async {
    emit(AuthLoading());
    final result = await signInLegacyWithPasswordUseCase(
      username: username,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> requestPasswordReset(String email) async {
    emit(AuthLoading());
    final result = await requestPasswordResetUseCase(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthMessage(passwordResetRequestMessage)),
    );
  }

  Future<void> beginAccountUpgrade(String email, String displayName) async {
    emit(AuthLoading());
    final result = await beginAccountUpgradeUseCase(
      email: email,
      displayName: displayName,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (userId) => emit(AuthUpgradePending(userId)),
    );
  }

  Future<void> setVerifiedAccountPassword(String password) async {
    emit(AuthLoading());
    final result = await setVerifiedAccountPasswordUseCase(password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthMessage('Your account upgrade is complete.')),
    );
  }

  Future<void> updateRecoveredPassword(String password) async {
    emit(AuthLoading());
    final result = await updateRecoveredPasswordUseCase(password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordUpdated()),
    );
  }
}

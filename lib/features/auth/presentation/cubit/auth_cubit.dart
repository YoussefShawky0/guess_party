import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/app_error_code.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;

  AuthCubit({required AuthRepository repository})
    : _repository = repository,
      super(AuthInitial());

  Future<void> signIn(String username) async {
    emit(AuthLoading());

    final result = await _repository.signInAsGuest(username);

    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signUp(String email, String displayName, String password) async {
    emit(AuthLoading());

    final result = await _repository.signUpWithPassword(
      email: email,
      displayName: displayName,
      password: password,
    );

    result.fold(
      (failure) => emit(
        failure is EmailVerificationRequiredFailure
            ? AuthMessage(failure.code)
            : AuthError(failure.code),
      ),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signInWithPassword(String email, String password) async {
    emit(AuthLoading());

    final result = await _repository.signInWithPassword(
      email: email,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signInLegacyWithPassword(
    String username,
    String password,
  ) async {
    emit(AuthLoading());
    final result = await _repository.signInLegacyWithPassword(
      username: username,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> requestPasswordReset(String email) async {
    emit(AuthLoading());
    final result = await _repository.requestPasswordReset(email);
    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (_) => emit(const AuthMessage(AppErrorCode.passwordResetRequested)),
    );
  }

  Future<void> beginAccountUpgrade(String email, String displayName) async {
    emit(AuthLoading());
    final result = await _repository.beginAccountUpgrade(
      email: email,
      displayName: displayName,
    );
    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (userId) => emit(AuthUpgradePending(userId)),
    );
  }

  Future<void> setVerifiedAccountPassword(String password) async {
    emit(AuthLoading());
    final result = await _repository.setVerifiedAccountPassword(password);
    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (_) => emit(const AuthMessage(AppErrorCode.accountUpgradeComplete)),
    );
  }

  Future<void> updateRecoveredPassword(String password) async {
    emit(AuthLoading());
    final result = await _repository.updateRecoveredPassword(password);
    result.fold(
      (failure) => emit(AuthError(failure.code)),
      (_) => emit(const AuthPasswordUpdated()),
    );
  }
}

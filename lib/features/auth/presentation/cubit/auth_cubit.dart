import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in_guest.dart';
import '../../domain/usecases/sign_in_with_password.dart';
import '../../domain/usecases/sign_up_with_password.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInGuest signInGuest;
  final SignUpWithPassword signUpWithPassword;
  final SignInWithPassword signInWithPasswordUseCase;

  AuthCubit({
    required this.signInGuest,
    required this.signUpWithPassword,
    required this.signInWithPasswordUseCase,
  }) : super(AuthInitial());

  Future<void> signIn(String username) async {
    emit(AuthLoading());

    final result = await signInGuest(username);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signUp(String username, String password) async {
    emit(AuthLoading());

    final result = await signUpWithPassword(
      username: username,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }

  Future<void> signInWithPassword(String username, String password) async {
    emit(AuthLoading());

    final result = await signInWithPasswordUseCase(
      username: username,
      password: password,
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (player) => emit(AuthSuccess(player)),
    );
  }
}

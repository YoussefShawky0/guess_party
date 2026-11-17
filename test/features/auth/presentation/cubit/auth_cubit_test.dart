import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/auth/domain/repositories/auth_repository.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:guess_party/features/auth/presentation/cubit/auth_state.dart';

void main() {
  test('password reset always exposes the approved generic response', () async {
    final repository = FakeAuthRepository();
    final cubit = buildCubit(repository);

    await cubit.requestPasswordReset('person@example.com');

    expect(cubit.state, const AuthMessage(AppErrorCode.passwordResetRequested));
    expect(repository.requestedResetEmail, 'person@example.com');
    await cubit.close();
  });

  test('unverified registration requests verification without login', () async {
    final repository = FakeAuthRepository(requireEmailVerification: true);
    final cubit = buildCubit(repository);

    await cubit.signUp('person@example.com', 'Person', 'password123');

    expect(
      cubit.state,
      const AuthMessage(AppErrorCode.emailVerificationRequired),
    );
    await cubit.close();
  });
}

AuthCubit buildCubit(AuthRepository repository) =>
    AuthCubit(repository: repository);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.requireEmailVerification = false});

  final bool requireEmailVerification;
  String? requestedResetEmail;

  @override
  ResultVoid requestPasswordReset(String email) async {
    requestedResetEmail = email;
    return const Right(null);
  }

  @override
  ResultFuture<String> beginAccountUpgrade({
    required String email,
    required String displayName,
  }) => throw UnimplementedError();
  @override
  ResultFuture<String> getCurrentUserId() => throw UnimplementedError();
  @override
  ResultFuture<Player> signInAsGuest(String username) =>
      throw UnimplementedError();
  @override
  ResultFuture<Player> signInLegacyWithPassword({
    required String username,
    required String password,
  }) => throw UnimplementedError();
  @override
  ResultFuture<Player> signInWithPassword({
    required String email,
    required String password,
  }) => throw UnimplementedError();
  @override
  ResultFuture<Player> signUpWithPassword({
    required String email,
    required String displayName,
    required String password,
  }) async {
    if (requireEmailVerification) {
      return const Left(
        EmailVerificationRequiredFailure(
          'verification required',
          code: AppErrorCode.emailVerificationRequired,
        ),
      );
    }
    throw UnimplementedError();
  }

  @override
  ResultVoid setVerifiedAccountPassword(String password) =>
      throw UnimplementedError();
  @override
  ResultVoid updateRecoveredPassword(String password) =>
      throw UnimplementedError();
}

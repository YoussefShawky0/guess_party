import 'package:dartz/dartz.dart';

import '../../../../core/error/app_error_code.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_client.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthSessionService authSessionService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.authSessionService,
  });

  @override
  Future<Either<Failure, Player>> signInAsGuest(String username) async {
    try {
      final player = await remoteDataSource.signInAsGuest(username);
      return Right(player);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, String>> getCurrentUserId() async {
    try {
      final userId = await remoteDataSource.getCurrentUserId();
      return Right(userId);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, Player>> signUpWithPassword({
    required String email,
    required String displayName,
    required String password,
  }) async {
    try {
      final player = await remoteDataSource.signUpWithPassword(
        email,
        displayName,
        password,
      );
      return Right(player);
    } on EmailVerificationRequiredException {
      return const Left(
        EmailVerificationRequiredFailure(
          'Email verification required',
          code: AppErrorCode.emailVerificationRequired,
        ),
      );
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, Player>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final player = await remoteDataSource.signInWithPassword(email, password);
      return Right(player);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, Player>> signInLegacyWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      return Right(
        await remoteDataSource.signInLegacyWithPassword(username, password),
      );
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset(String email) async {
    try {
      await remoteDataSource.requestPasswordReset(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, String>> beginAccountUpgrade({
    required String email,
    required String displayName,
  }) async {
    try {
      return Right(
        await remoteDataSource.beginAccountUpgrade(email, displayName),
      );
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> setVerifiedAccountPassword(
    String password,
  ) async {
    try {
      await remoteDataSource.setVerifiedAccountPassword(password);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }

  @override
  Future<Either<Failure, void>> updateRecoveredPassword(String password) async {
    if (!authSessionService.hasPasswordRecoverySession) {
      return const Left(
        ServerFailure(
          'No password recovery session',
          code: AppErrorCode.recoveryLinkInvalid,
        ),
      );
    }
    try {
      await remoteDataSource.updateRecoveredPassword(password);
      authSessionService.consumePasswordRecoverySession();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }
}

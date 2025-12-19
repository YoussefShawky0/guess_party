import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/error_handler.dart';
import '../../domain/entities/player.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Player>> signInAsGuest(String username) async {
    try {
      final player = await remoteDataSource.signInAsGuest(username);
      return Right(player);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getCurrentUserId() async {
    try {
      final userId = await remoteDataSource.getCurrentUserId();
      return Right(userId);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Player>> signUpWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      final player = await remoteDataSource.signUpWithPassword(
        username,
        password,
      );
      return Right(player);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, Player>> signInWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      final player = await remoteDataSource.signInWithPassword(
        username,
        password,
      );
      return Right(player);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }
}

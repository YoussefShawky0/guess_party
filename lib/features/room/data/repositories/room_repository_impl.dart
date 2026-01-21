import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/error_handler.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource remoteDataSource;

  RoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Room>> createRoom({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  }) async {
    try {
      final room = await remoteDataSource.createRoom(
        category: category,
        maxRounds: maxRounds,
        maxPlayers: maxPlayers,
        roundDuration: roundDuration,
        gameMode: gameMode,
      );
      return Right(room);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, Player>> addPlayerToRoom({
    required String roomId,
    required String username,
    required bool isHost,
  }) async {
    try {
      final player = await remoteDataSource.addPlayerToRoom(
        roomId: roomId,
        username: username,
        isHost: isHost,
      );
      return Right(player);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoomDetails({required String roomId}) async {
    try {
      final room = await remoteDataSource.getRoomDetails(roomId: roomId);
      return Right(room);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, List<Player>>> getRoomPlayers({
    required String roomId,
  }) async {
    try {
      final players = await remoteDataSource.getRoomPlayers(roomId: roomId);
      return Right(players);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, Room>> getRoomByCode({
    required String roomCode,
  }) async {
    try {
      final room = await remoteDataSource.getRoomByCode(roomCode: roomCode);
      return Right(room);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, void>> startGame(String roomId) async {
    try {
      await remoteDataSource.startGame(roomId);
      return const Right(null);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, void>> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
    try {
      await remoteDataSource.updatePlayerStatus(
        playerId: playerId,
        isOnline: isOnline,
      );
      return const Right(null);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, void>> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    try {
      await remoteDataSource.leaveRoom(
        playerId: playerId,
        roomId: roomId,
        isHost: isHost,
      );
      return const Right(null);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }
}

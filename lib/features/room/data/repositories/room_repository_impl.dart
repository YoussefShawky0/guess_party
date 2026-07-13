import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/error_handler.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource remoteDataSource;

  RoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, RoomSession>> createRoom({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  }) async {
    try {
      final room = await remoteDataSource.createRoom(
        requestId: requestId,
        category: category,
        maxRounds: maxRounds,
        maxPlayers: maxPlayers,
        roundDuration: roundDuration,
        gameMode: gameMode,
        hostUsername: hostUsername,
        localNames: localNames,
      );
      return Right(room);
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      final userFriendlyMsg = ErrorHandler.getUserFriendlyMessage(errorMsg);
      return Left(ServerFailure(userFriendlyMsg));
    }
  }

  @override
  Future<Either<Failure, RoomSession>> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    try {
      return Right(
        await remoteDataSource.joinRoom(roomCode: roomCode, username: username),
      );
    } catch (e) {
      final errorMsg = ErrorHandler.extractErrorMessage(e);
      return Left(ServerFailure(ErrorHandler.getUserFriendlyMessage(errorMsg)));
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
  Stream<Room> watchRoomDetails({required String roomId}) {
    return remoteDataSource.watchRoomDetails(roomId: roomId);
  }

  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) {
    return remoteDataSource.watchRoomPlayers(roomId: roomId);
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
  Future<Either<Failure, String>> startGame(String roomId) async {
    try {
      return Right(await remoteDataSource.startGame(roomId));
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
  Future<Either<Failure, void>> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  }) async {
    try {
      await remoteDataSource.markStalePlayersOffline(
        roomId: roomId,
        staleSeconds: staleSeconds,
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

import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';

abstract class RoomRepository {
  ResultFuture<RoomSession> createRoom({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  });

  ResultFuture<RoomSession> joinRoom({
    required String roomCode,
    required String username,
  });

  ResultFuture<Room> getRoomDetails({required String roomId});

  Stream<Room> watchRoomDetails({required String roomId});

  Stream<List<Player>> watchRoomPlayers({required String roomId});

  ResultFuture<List<Player>> getRoomPlayers({required String roomId});

  ResultFuture<Room> getRoomByCode({required String roomCode});

  ResultFuture<String> startGame(String roomId);

  ResultFuture<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  });

  ResultFuture<void> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  });

  ResultFuture<void> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  });
}

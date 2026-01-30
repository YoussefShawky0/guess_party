import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';

abstract class RoomRepository {
  ResultFuture<Room> createRoom({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  });

  ResultFuture<Player> addPlayerToRoom({
    required String roomId,
    required String username,
    required bool isHost,
    bool isLocalPlayer = false,
  });

  ResultFuture<Room> getRoomDetails({required String roomId});

  ResultFuture<List<Player>> getRoomPlayers({required String roomId});

  ResultFuture<Room> getRoomByCode({required String roomCode});

  ResultFuture<void> startGame(String roomId);

  ResultFuture<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  });

  ResultFuture<void> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  });
}

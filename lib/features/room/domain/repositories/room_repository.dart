import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
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

  ResultFuture<RoomSession> createRematch({
    required String requestId,
    required String previousRoomId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String hostUsername,
    required List<String> localNames,
  });

  /// Right(null) when the invite was declined.
  ResultFuture<RoomSession?> respondToRematchInvite({
    required String roomId,
    required bool accept,
  });

  Stream<List<RoomInvite>> watchRoomInvites({required String roomId});

  Stream<List<RoomInvite>> watchMyRematchInvites({
    required String previousRoomId,
    required String userId,
  });

  ResultFuture<Room> getRoomDetails({required String roomId});

  Stream<Room> watchRoomDetails({required String roomId});

  Stream<List<Player>> watchRoomPlayers({required String roomId});

  ResultFuture<List<Player>> getRoomPlayers({required String roomId});

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

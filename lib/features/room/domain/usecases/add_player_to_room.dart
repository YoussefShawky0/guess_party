
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class AddPlayerToRoom {
  final RoomRepository repository;

  AddPlayerToRoom(this.repository);

  ResultFuture<Player> call ({
    required String roomId,
    required String username,
    required bool isHost,
    }) async {
      return await repository.addPlayerToRoom(
        roomId: roomId,
        username: username,
        isHost: isHost,
      );
    }
  }

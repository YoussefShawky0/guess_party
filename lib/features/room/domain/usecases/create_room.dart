import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class CreateRoom {
  final RoomRepository repository;

  CreateRoom(this.repository);

  ResultFuture<Room> call({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  }) async {
    return repository.createRoom(
      category: category,
      maxRounds: maxRounds,
      maxPlayers: maxPlayers,
      roundDuration: roundDuration,
      gameMode: gameMode,
    );
  }
}

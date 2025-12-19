import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class GetRoomPlayers {
  final RoomRepository repository;

  GetRoomPlayers(this.repository);

  ResultFuture<List<Player>> call({required String roomId}) {
    return repository.getRoomPlayers(roomId: roomId);
  }
}

import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class WatchRoomPlayers {
  const WatchRoomPlayers(this.repository);

  final RoomRepository repository;

  Stream<List<Player>> call({required String roomId}) =>
      repository.watchRoomPlayers(roomId: roomId);
}

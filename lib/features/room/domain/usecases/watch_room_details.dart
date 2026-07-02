import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class WatchRoomDetails {
  final RoomRepository repository;

  WatchRoomDetails(this.repository);

  Stream<Room> call({required String roomId}) {
    return repository.watchRoomDetails(roomId: roomId);
  }
}

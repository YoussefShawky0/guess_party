import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class GetRoomByCode {
  final RoomRepository repository;

  GetRoomByCode(this.repository);

  ResultFuture<Room> call({required String roomCode}) {
    return repository.getRoomByCode(roomCode: roomCode);
  }
}

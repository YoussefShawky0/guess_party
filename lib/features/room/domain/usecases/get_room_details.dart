import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class GetRoomDetails {
  final RoomRepository repository;

  GetRoomDetails(this.repository);

  ResultFuture<Room> call({required String roomId}) {
    return repository.getRoomDetails(roomId: roomId);
  }
}

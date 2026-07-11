import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class JoinRoom {
  final RoomRepository repository;

  JoinRoom(this.repository);

  ResultFuture<RoomSession> call({
    required String roomCode,
    required String username,
  }) {
    return repository.joinRoom(roomCode: roomCode, username: username);
  }
}

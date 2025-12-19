import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class LeaveRoom {
  final RoomRepository repository;

  LeaveRoom(this.repository);

  Future<Either<Failure, void>> call({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    return await repository.leaveRoom(
      playerId: playerId,
      roomId: roomId,
      isHost: isHost,
    );
  }
}

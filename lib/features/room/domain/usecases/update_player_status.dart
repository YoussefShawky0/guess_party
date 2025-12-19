import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class UpdatePlayerStatus {
  final RoomRepository repository;

  UpdatePlayerStatus(this.repository);

  Future<Either<Failure, void>> call({
    required String playerId,
    required bool isOnline,
  }) async {
    return await repository.updatePlayerStatus(
      playerId: playerId,
      isOnline: isOnline,
    );
  }
}

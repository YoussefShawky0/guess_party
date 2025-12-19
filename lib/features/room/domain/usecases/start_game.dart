import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class StartGame {
  final RoomRepository repository;

  StartGame(this.repository);

  Future<Either<Failure, void>> call(String roomId) async {
    return await repository.startGame(roomId);
  }
}

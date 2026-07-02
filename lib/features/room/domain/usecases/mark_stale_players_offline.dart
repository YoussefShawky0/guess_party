import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class MarkStalePlayersOffline {
  final RoomRepository repository;

  MarkStalePlayersOffline(this.repository);

  Future<Either<Failure, void>> call({required int staleSeconds}) async {
    return await repository.markStalePlayersOffline(staleSeconds: staleSeconds);
  }
}

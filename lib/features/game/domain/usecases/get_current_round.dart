import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class GetCurrentRound {
  final GameRepository repository;

  GetCurrentRound(this.repository);

  Future<Either<Failure, RoundInfo>> call({required String roomId}) async {
    return await repository.getCurrentRound(roomId: roomId);
  }
}

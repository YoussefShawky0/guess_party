import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class AdvancePhase {
  final GameRepository repository;
  AdvancePhase({required this.repository});

  Future<Either<Failure, RoundInfo>> call({
    required String roundId,
  }) async{
    return await repository.advancePhase(roundId: roundId);
  }
}

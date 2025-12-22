import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class SubmitVote {
  final GameRepository repository;
  SubmitVote(this.repository);

  Future<Either<Failure, void>> call({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    if (voterId == votedPlayerId) {
      return Left(ValidationFailure('لا يمكنك التصويت لنفسك!'));
    }
    return await repository.submitVote(
      roundId: roundId,
      voterId: voterId,
      votedPlayerId: votedPlayerId,
    );
  }
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

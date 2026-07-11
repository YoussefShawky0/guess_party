import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/entities/finalize_voting_result.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class FinalizeVoting {
  final GameRepository repository;

  FinalizeVoting(this.repository);

  ResultFuture<FinalizeVotingResult> call({
    required String roundId,
    required String reason,
  }) {
    return repository.finalizeVoting(roundId: roundId, reason: reason);
  }
}

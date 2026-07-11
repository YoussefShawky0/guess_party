import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class AdvanceToVoting {
  final GameRepository repository;

  AdvanceToVoting(this.repository);

  ResultFuture<RoundInfo> call({required String roundId}) {
    return repository.advanceToVoting(roundId: roundId);
  }
}

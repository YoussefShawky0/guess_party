import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class ExtendLocalRoleReveal {
  final GameRepository repository;

  ExtendLocalRoleReveal(this.repository);

  ResultFuture<void> call({required String roundId, required int seconds}) {
    return repository.extendLocalRoleReveal(roundId: roundId, seconds: seconds);
  }
}

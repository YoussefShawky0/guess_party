import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class CreateNextRound {
  final GameRepository repository;

  CreateNextRound(this.repository);

  ResultFuture<RoundInfo> call({
    required String roomId,
    required int expectedRoundNumber,
  }) {
    return repository.createNextRound(
      roomId: roomId,
      expectedRoundNumber: expectedRoundNumber,
    );
  }
}

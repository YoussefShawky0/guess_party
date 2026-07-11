import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class FinishGame {
  final GameRepository repository;

  FinishGame(this.repository);

  ResultFuture<void> call({required String roomId}) {
    return repository.finishGame(roomId: roomId);
  }
}

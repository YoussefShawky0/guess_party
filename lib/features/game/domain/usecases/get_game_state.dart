import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class GetGameState {
  final GameRepository repository;

  GetGameState({required this.repository});

  Future<Either<Failure, GameState>> call({
    required String roomId,
    required String currentPlayerId,
  }) async {
    return await repository.getGameState(
      roomId: roomId,
      currentPlayerId: currentPlayerId,
    );
  }
}

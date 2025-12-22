import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';

abstract class GameRepository {
  // Get current game state for a room
  Future<Either<Failure, GameState>> getGameState({
    required String roomId,
    required String currentPlayerId,
  });

  // Get current round information
  Future<Either<Failure, RoundInfo>> getCurrentRound({required String roomId});

  // Submit a hint for the current round
  Future<Either<Failure, void>> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  });

  // Submit a vote for the current round
  Future<Either<Failure, void>> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  });

  /// Start next phase (hints -> voting -> results)
  Future<Either<Failure, RoundInfo>> advancePhase({required String roundId});

  // Calculate and update scores after voting
  Future<Either<Failure, Map<String, int>>> calculateScores({
    required String roundId,
  });

  // Create next round
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int roundNumber,
  });

  // End the game and update final scores
  Future<Either<Failure, void>> endGame({required String roomId});

  // Subscribe to round updates (real-time)
  Stream<RoundInfo> watchRoundUpdates({required String roundId});

  // Subscribe to hints updates (real-time)
  Stream<Map<String, String>> watchHintsUpdates({required String roundId});

  // Subscribe to votes updates (real-time)
  Stream<Map<String, String>> watchVotesUpdates({required String roundId});
}

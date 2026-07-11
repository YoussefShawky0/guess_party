import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/finalize_voting_result.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_bundle.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
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

  Future<Either<Failure, RoundInfo>> advanceToVoting({required String roundId});

  Future<Either<Failure, FinalizeVotingResult>> finalizeVoting({
    required String roundId,
    required String reason,
  });

  Future<Either<Failure, void>> extendLocalRoleReveal({
    required String roundId,
    required int seconds,
  });

  Future<Either<Failure, LocalRoleRevealBundle>> getLocalRoleRevealBundle({
    required String roundId,
  });

  Future<Either<Failure, LocalRoleRevealData>> getLocalRoleRevealData({
    required String roomId,
  });

  // Create next round
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int expectedRoundNumber,
  });

  Future<Either<Failure, void>> finishGame({required String roomId});

  // Subscribe to round updates (real-time)
  Stream<RoundInfo> watchRoundUpdates({required String roundId});

  // Subscribe to room online players updates (real-time)
  Stream<List<Player>> watchRoomPlayers({required String roomId});
}

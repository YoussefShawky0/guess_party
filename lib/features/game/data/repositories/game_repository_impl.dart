import 'dart:math';
import 'package:dartz/dartz.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/error_handler.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final RoomRemoteDataSource roomRemoteDataSource;
  final SupabaseClient client;

  GameRepositoryImpl({
    required this.remoteDataSource,
    required this.roomRemoteDataSource,
    required this.client,
  });

  Future<Failure> _serverFailure(
    String operation,
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> data = const {},
  }) async {
    await ErrorHandler.reportException(
      error,
      stackTrace: stackTrace,
      operation: operation,
      data: data,
    );

    final errorMessage = ErrorHandler.extractErrorMessage(error);
    return ServerFailure(ErrorHandler.getUserFriendlyMessage(errorMessage));
  }

  @override
  Future<Either<Failure, RoundInfo>> getCurrentRound({
    required String roomId,
  }) async {
    try {
      final roundModel = await remoteDataSource.getCurrentRound(roomId: roomId);
      return Right(roundModel.toEntity());
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'getCurrentRound',
          e,
          stackTrace,
          data: {'roomId': roomId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, GameState>> getGameState({
    required String roomId,
    required String currentPlayerId,
  }) async {
    try {
      final roundModel = await remoteDataSource.getCurrentRound(roomId: roomId);

      final playerModels = await remoteDataSource.getRoomPlayers(
        roomId: roomId,
      );
      final players = playerModels.map((m) => m.toEntity()).toList();

      final scores = await remoteDataSource.getPlayerScores(roomId: roomId);

      final room = await roomRemoteDataSource.getRoomDetails(roomId: roomId);

      final gameState = GameState(
        roomId: roomId,
        currentRound: roundModel.toEntity(),
        players: players,
        currentPlayerId: currentPlayerId,
        totalRounds: room.maxRounds,
        roundDuration: room.roundDuration,
        playerScores: scores,
        gameMode: room.gameMode,
      );

      return Right(gameState);
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'getGameState',
          e,
          stackTrace,
          data: {'roomId': roomId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    try {
      await remoteDataSource.submitHint(
        roundId: roundId,
        playerId: playerId,
        hint: hint,
      );
      return const Right(null);
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'submitHint',
          e,
          stackTrace,
          data: {'roundId': roundId, 'playerId': playerId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    try {
      await remoteDataSource.submitVote(
        roundId: roundId,
        voterId: voterId,
        votedPlayerId: votedPlayerId,
      );
      return const Right(null);
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'submitVote',
          e,
          stackTrace,
          data: {'roundId': roundId, 'voterId': voterId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> advancePhase({
    required String roundId,
  }) async {
    try {
      // Fetch current round phase only (no JOIN needed - durations are fixed)
      final currentRoundResponse = await client
          .from('rounds')
          .select('phase, room_id')
          .eq('id', roundId)
          .single();

      final currentPhase = currentRoundResponse['phase'] as String;
      String newPhase;
      int phaseDuration;

      switch (currentPhase) {
        case 'hints':
          newPhase = 'voting';
          phaseDuration = GameConstants.votingPhaseDurationSeconds;
          break;
        case 'voting':
          newPhase = 'results';
          phaseDuration = GameConstants.resultsPhaseDurationSeconds;
          break;
        default:
          // Already at results phase — no-op, return current round as-is
          final roundModel = await remoteDataSource.getCurrentRound(
            roomId: currentRoundResponse['room_id'] as String,
          );
          return Right(roundModel.toEntity());
      }

      final phaseEndTime = DateTime.now().toUtc().add(
        Duration(seconds: phaseDuration),
      );

      final updatedRound = await remoteDataSource.updateRoundPhase(
        roundId: roundId,
        newPhase: newPhase,
        phaseEndTime: phaseEndTime,
      );

      return Right(updatedRound.toEntity());
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'advancePhase',
          e,
          stackTrace,
          data: {'roundId': roundId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> calculateScores({
    required String roundId,
    required Map<String, int> currentScores,
  }) async {
    try {
      // Fetch round info
      final roundResponse = await client
          .from('rounds')
          .select()
          .eq('id', roundId)
          .single();

      final imposterPlayerId = roundResponse['imposter_player_id'] as String;

      // Fetch votes
      final votes = await remoteDataSource.getVotesForRound(roundId: roundId);

      // Count votes per player
      final voteCounts = <String, int>{};
      for (final votedPlayerId in votes.values) {
        voteCounts[votedPlayerId] = (voteCounts[votedPlayerId] ?? 0) + 1;
      }

      // Find the most-voted player
      String? mostVotedPlayerId;
      int maxVotes = 0;
      for (final entry in voteCounts.entries) {
        if (entry.value > maxVotes) {
          maxVotes = entry.value;
          mostVotedPlayerId = entry.key;
        }
      }

      // Use in-memory scores passed from state instead of reading DB
      // (avoids RLS restrictions and race conditions)
      final newScores = Map<String, int>.from(currentScores);

      // Award points
      // Always: +10 to anyone who voted for the imposter (correct even if not the majority)
      for (final entry in votes.entries) {
        final voterId = entry.key;
        final votedId = entry.value;
        if (votedId == imposterPlayerId) {
          newScores[voterId] = (newScores[voterId] ?? 0) + 10;
        }
      }

      // Imposter wins +20 if they were NOT the most-voted (majority wrong)
      if (mostVotedPlayerId != imposterPlayerId) {
        newScores[imposterPlayerId] = (newScores[imposterPlayerId] ?? 0) + 20;
      }
      // If imposter was caught (majority correct) — no bonus for imposter

      // Persist scores to DB (best-effort — RLS may block writes for some players)
      // In-memory scores are always the source of truth
      try {
        await remoteDataSource.updatePlayerScores(scores: newScores);
      } catch (_) {
        // Ignore DB write failure — in-memory scores are correct
      }

      return Right(newScores);
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'calculateScores',
          e,
          stackTrace,
          data: {'roundId': roundId},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int roundNumber,
  }) async {
    try {
      // ── Guard: check if this round was already created (double-tap / race condition) ──
      final List existingList = await client
          .from('rounds')
          .select()
          .eq('room_id', roomId)
          .eq('round_number', roundNumber);

      if (existingList.isNotEmpty) {
        // Round already exists — return its data instead of inserting again
        final existing = existingList.first as Map<String, dynamic>;
        final character = await remoteDataSource.getCharacter(
          characterId: existing['character_id'] as String,
        );
        final players = await remoteDataSource.getRoomPlayers(roomId: roomId);
        final playerIds = players.map((p) => p.id).toList();
        final hints = await remoteDataSource.getHintsForRound(
          roundId: existing['id'] as String,
        );
        final votes = await remoteDataSource.getVotesForRound(
          roundId: existing['id'] as String,
        );
        final model = RoundInfoModel.fromJson(
          existing,
          character.toEntity(),
          playerIds,
          hints,
          votes,
        );
        return Right(model.toEntity());
      }

      // ── Normal flow ─────────────────────────────────────────────────────
      final players = await remoteDataSource.getRoomPlayers(roomId: roomId);

      // Pick a random imposter
      final rng = Random();
      final imposterIndex = rng.nextInt(players.length);
      final imposterPlayerId = players[imposterIndex].id;

      // Fetch room details to get roundDuration and category
      final room = await roomRemoteDataSource.getRoomDetails(roomId: roomId);

      // Fetch a random character matching the room's category
      final isRoomMix = room.category == 'mix';
      var charactersQuery = client
          .from('characters')
          .select()
          .eq('is_active', true);

      // Filter by category unless room is set to mix
      if (!isRoomMix) {
        charactersQuery = charactersQuery.eq('category', room.category);
      }

      final charactersResponse = await charactersQuery.limit(100);

      final characters = charactersResponse as List;
      if (characters.isEmpty) {
        throw Exception('No characters available');
      }

      final characterIndex = rng.nextInt(characters.length);
      final characterId = characters[characterIndex]['id'] as String;

      // Create new round with duration from room settings
      final newRound = await remoteDataSource.createRound(
        roomId: roomId,
        imposterPlayerId: imposterPlayerId,
        characterId: characterId,
        roundNumber: roundNumber,
        roundDurationSeconds: room.roundDuration,
      );

      return Right(newRound.toEntity());
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'createNextRound',
          e,
          stackTrace,
          data: {'roomId': roomId, 'roundNumber': roundNumber},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> endGame({required String roomId}) async {
    try {
      await remoteDataSource.updateRoomStatus(
        roomId: roomId,
        status: 'finished',
      );
      return const Right(null);
    } catch (e, stackTrace) {
      return Left(
        await _serverFailure(
          'endGame',
          e,
          stackTrace,
          data: {'roomId': roomId},
        ),
      );
    }
  }

  @override
  Stream<RoundInfo> watchRoundUpdates({required String roundId}) async* {
    while (true) {
      try {
        await for (final _ in remoteDataSource.watchRoundChanges(
          roundId: roundId,
        )) {
          try {
            // Fetch full round details
            final roundResponse = await client
                .from('rounds')
                .select()
                .eq('id', roundId)
                .single();

            final character = await remoteDataSource.getCharacter(
              characterId: roundResponse['character_id'] as String,
            );

            final roomId = roundResponse['room_id'] as String;
            final players = await remoteDataSource.getRoomPlayers(
              roomId: roomId,
            );
            final playerIds = players.map((p) => p.id).toList();

            final hints = await remoteDataSource.getHintsForRound(
              roundId: roundId,
            );
            final votes = await remoteDataSource.getVotesForRound(
              roundId: roundId,
            );

            final roundModel = RoundInfoModel.fromJson(
              roundResponse,
              character.toEntity(),
              playerIds,
              hints,
              votes,
            );

            yield roundModel.toEntity();
          } catch (e, stackTrace) {
            await ErrorHandler.reportException(
              e,
              stackTrace: stackTrace,
              operation: 'watchRoundUpdates.processEvent',
              data: {'roundId': roundId},
            );
          }
        }
        break; // Stream ended normally
      } catch (e, stackTrace) {
        await ErrorHandler.reportException(
          e,
          stackTrace: stackTrace,
          operation: 'watchRoundUpdates.subscribe',
          data: {'roundId': roundId},
        );
        // WebSocket dropped — wait and reconnect
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  @override
  Stream<Map<String, String>> watchHintsUpdates({
    required String roundId,
  }) async* {
    while (true) {
      try {
        await for (final _ in remoteDataSource.watchHintsChanges(
          roundId: roundId,
        )) {
          try {
            final hints = await remoteDataSource.getHintsForRound(
              roundId: roundId,
            );
            yield hints;
          } catch (e, stackTrace) {
            await ErrorHandler.reportException(
              e,
              stackTrace: stackTrace,
              operation: 'watchHintsUpdates.processEvent',
              data: {'roundId': roundId},
            );
          }
        }
        break;
      } catch (e, stackTrace) {
        await ErrorHandler.reportException(
          e,
          stackTrace: stackTrace,
          operation: 'watchHintsUpdates.subscribe',
          data: {'roundId': roundId},
        );
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  @override
  Stream<Map<String, String>> watchVotesUpdates({
    required String roundId,
  }) async* {
    while (true) {
      try {
        await for (final _ in remoteDataSource.watchVotesChanges(
          roundId: roundId,
        )) {
          try {
            final votes = await remoteDataSource.getVotesForRound(
              roundId: roundId,
            );
            yield votes;
          } catch (e, stackTrace) {
            await ErrorHandler.reportException(
              e,
              stackTrace: stackTrace,
              operation: 'watchVotesUpdates.processEvent',
              data: {'roundId': roundId},
            );
          }
        }
        break;
      } catch (e, stackTrace) {
        await ErrorHandler.reportException(
          e,
          stackTrace: stackTrace,
          operation: 'watchVotesUpdates.subscribe',
          data: {'roundId': roundId},
        );
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }
}

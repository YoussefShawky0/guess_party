import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/error_handler.dart';
import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/data/datasources/game_remote_data_source.dart';
import 'package:guess_party/features/game/data/models/character_model.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/game/domain/entities/finalize_voting_result.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_bundle.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/data/datasources/room_remote_data_source.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';

class GameRepositoryImpl implements GameRepository {
  final GameRemoteDataSource remoteDataSource;
  final RoomRemoteDataSource roomRemoteDataSource;

  GameRepositoryImpl({
    required this.remoteDataSource,
    required this.roomRemoteDataSource,
  });

  Stream<T> _watchWithRetry<S, T>({
    required Stream<S> Function() streamFactory,
    required FutureOr<T> Function(S event) eventMapper,
    required String operationName,
    Map<String, Object?> logData = const {},
    int maxRetries = 10,
  }) {
    late final StreamController<T> controller;
    StreamSubscription<S>? innerSubscription;
    Timer? retryTimer;
    var retryCount = 0;
    var cancelled = false;
    var retryScheduled = false;

    const baseDelay = Duration(seconds: 3);
    const maxDelay = Duration(seconds: 30);

    Duration retryDelay(int attempt) {
      final multiplier = 1 << attempt.clamp(0, 4);
      final exponentialMilliseconds = baseDelay.inMilliseconds * multiplier;
      final cappedMilliseconds = min(
        exponentialMilliseconds,
        maxDelay.inMilliseconds,
      );
      final jitterMilliseconds = Random().nextInt(
        (cappedMilliseconds * 0.2).round() + 1,
      );
      return Duration(
        milliseconds: min(
          cappedMilliseconds + jitterMilliseconds,
          maxDelay.inMilliseconds,
        ),
      );
    }

    Future<void> cancelInnerSubscription() async {
      final subscription = innerSubscription;
      innerSubscription = null;
      if (subscription != null) await subscription.cancel();
    }

    late void Function() subscribe;

    Future<void> scheduleRetry({Object? error, StackTrace? stackTrace}) async {
      if (cancelled || controller.isClosed || retryScheduled) return;
      retryScheduled = true;
      await cancelInnerSubscription();
      if (cancelled || controller.isClosed) return;

      if (retryCount >= maxRetries) {
        controller.addError(
          StateError(
            '$operationName: max retries ($maxRetries) exceeded'
            '${error == null ? '' : ': $error'}',
          ),
          stackTrace,
        );
        await controller.close();
        return;
      }

      retryCount++;
      final delay = retryDelay(retryCount - 1);
      await ErrorHandler.reportException(
        error ?? StateError('$operationName stream ended unexpectedly'),
        stackTrace: stackTrace,
        operation: '$operationName.subscribe',
        data: {
          ...logData,
          'retryAttempt': retryCount,
          'maxRetries': maxRetries,
          'retryDelayMs': delay.inMilliseconds,
        },
      );

      if (cancelled || controller.isClosed) return;
      retryTimer = Timer(delay, () {
        retryScheduled = false;
        if (!cancelled && !controller.isClosed) subscribe();
      });
    }

    subscribe = () {
      if (cancelled || controller.isClosed) return;
      try {
        innerSubscription = streamFactory().listen(
          (event) async {
            if (cancelled || controller.isClosed) return;
            innerSubscription?.pause();
            retryCount = 0;
            try {
              final mapped = await eventMapper(event);
              if (!cancelled && !controller.isClosed) controller.add(mapped);
            } catch (error, stackTrace) {
              await scheduleRetry(error: error, stackTrace: stackTrace);
            } finally {
              if (!cancelled) innerSubscription?.resume();
            }
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(scheduleRetry(error: error, stackTrace: stackTrace));
          },
          onDone: () => unawaited(scheduleRetry()),
          cancelOnError: true,
        );
      } catch (error, stackTrace) {
        unawaited(scheduleRetry(error: error, stackTrace: stackTrace));
      }
    };

    controller = StreamController<T>(
      onListen: subscribe,
      onCancel: () async {
        cancelled = true;
        retryTimer?.cancel();
        retryTimer = null;
        await cancelInnerSubscription();
      },
    );
    return controller.stream;
  }

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
    final message = ErrorHandler.extractErrorMessage(error);
    return ServerFailure(ErrorHandler.getUserFriendlyMessage(message));
  }

  @override
  Future<Either<Failure, RoundInfo>> getCurrentRound({
    required String roomId,
  }) async {
    try {
      final model = await remoteDataSource.getCurrentRound(roomId: roomId);
      return Right(model.toEntity());
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure(
          'getCurrentRound',
          error,
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
      final results = await Future.wait<Object>([
        remoteDataSource.getCurrentRound(roomId: roomId),
        remoteDataSource.getRoomPlayers(roomId: roomId),
        remoteDataSource.getPlayerScores(roomId: roomId),
        roomRemoteDataSource.getRoomDetails(roomId: roomId),
      ]);
      final round = results[0] as RoundInfoModel;
      final playerModels = results[1] as List<PlayerModel>;
      final scores = results[2] as Map<String, int>;
      final room = results[3] as Room;

      return Right(
        GameState(
          roomId: roomId,
          currentRound: round.toEntity(),
          players: playerModels.map((model) => model.toEntity()).toList(),
          currentPlayerId: currentPlayerId,
          totalRounds: room.maxRounds,
          roundDuration: room.roundDuration,
          playerScores: scores,
          gameMode: room.gameMode,
        ),
      );
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure(
          'getGameState',
          error,
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
    } catch (error, stackTrace) {
      return Left(await _serverFailure('submitHint', error, stackTrace));
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
    } catch (error, stackTrace) {
      return Left(await _serverFailure('submitVote', error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> advanceToVoting({
    required String roundId,
  }) async {
    try {
      await remoteDataSource.advanceToVoting(roundId: roundId);
      final snapshot = await remoteDataSource.getRoundSnapshot(
        roundId: roundId,
      );
      return Right(snapshot.toEntity());
    } catch (error, stackTrace) {
      return Left(await _serverFailure('advanceToVoting', error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, FinalizeVotingResult>> finalizeVoting({
    required String roundId,
    required String reason,
  }) async {
    try {
      final result = await remoteDataSource.finalizeVoting(
        roundId: roundId,
        reason: reason,
      );
      return Right(result);
    } catch (error, stackTrace) {
      return Left(await _serverFailure('finalizeVoting', error, stackTrace));
    }
  }

  @override
  Future<Either<Failure, void>> extendLocalRoleReveal({
    required String roundId,
    required int seconds,
  }) async {
    try {
      await remoteDataSource.extendLocalRoleReveal(
        roundId: roundId,
        seconds: seconds,
      );
      return const Right(null);
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure('extendLocalRoleReveal', error, stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, LocalRoleRevealBundle>> getLocalRoleRevealBundle({
    required String roundId,
  }) async {
    try {
      return Right(
        await remoteDataSource.getLocalRoleRevealBundle(roundId: roundId),
      );
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure('getLocalRoleRevealBundle', error, stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, LocalRoleRevealData>> getLocalRoleRevealData({
    required String roomId,
  }) async {
    try {
      final round = await remoteDataSource.getCurrentRound(roomId: roomId);
      final bundle = await remoteDataSource.getLocalRoleRevealBundle(
        roundId: round.id,
      );
      final results = await Future.wait<Object>([
        remoteDataSource.getCharacter(characterId: bundle.characterId),
        remoteDataSource.getRoomPlayers(roomId: roomId),
      ]);
      final character = results[0] as CharacterModel;
      final players = results[1] as List<PlayerModel>;
      return Right(
        LocalRoleRevealData(
          roundId: bundle.roundId,
          imposterPlayerId: bundle.imposterPlayerId,
          character: character.toEntity(),
          players: players.map((player) => player.toEntity()).toList(),
        ),
      );
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure('getLocalRoleRevealData', error, stackTrace),
      );
    }
  }

  @override
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int expectedRoundNumber,
  }) async {
    try {
      final roundId = await remoteDataSource.createNextRoundCommand(
        roomId: roomId,
        expectedRoundNumber: expectedRoundNumber,
      );
      final snapshot = await remoteDataSource.getRoundSnapshot(
        roundId: roundId,
      );
      return Right(snapshot.toEntity());
    } catch (error, stackTrace) {
      return Left(
        await _serverFailure(
          'createNextRound',
          error,
          stackTrace,
          data: {'roomId': roomId, 'expectedRoundNumber': expectedRoundNumber},
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> finishGame({required String roomId}) async {
    try {
      await remoteDataSource.finishGameCommand(roomId: roomId);
      return const Right(null);
    } catch (error, stackTrace) {
      return Left(await _serverFailure('finishGame', error, stackTrace));
    }
  }

  @override
  Stream<RoundInfo> watchRoundUpdates({required String roundId}) {
    return _watchWithRetry<Map<String, dynamic>, RoundInfo>(
      streamFactory: () =>
          remoteDataSource.watchRoundRevision(roundId: roundId),
      eventMapper: (_) async => (await remoteDataSource.getRoundSnapshot(
        roundId: roundId,
      )).toEntity(),
      operationName: 'watchRoundUpdates',
      logData: {'roundId': roundId},
    );
  }

  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) {
    return _watchWithRetry<List<PlayerModel>, List<Player>>(
      streamFactory: () => remoteDataSource.watchPlayersChanges(roomId: roomId),
      eventMapper: (players) =>
          players.map((player) => player.toEntity()).toList(growable: false),
      operationName: 'watchRoomPlayers',
      logData: {'roomId': roomId},
    );
  }
}

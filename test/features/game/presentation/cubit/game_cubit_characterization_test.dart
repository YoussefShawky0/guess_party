import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/services/server_clock.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/finalize_voting_result.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart'
    as entity;
import 'package:guess_party/features/game/domain/entities/local_role_reveal_bundle.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/advance_to_voting.dart';
import 'package:guess_party/features/game/domain/usecases/create_next_round.dart';
import 'package:guess_party/features/game/domain/usecases/extend_local_role_reveal.dart';
import 'package:guess_party/features/game/domain/usecases/finalize_voting.dart';
import 'package:guess_party/features/game/domain/usecases/finish_game.dart';
import 'package:guess_party/features/game/domain/usecases/get_game_state.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

import '../../../../helpers/game_test_fixtures.dart';

void main() {
  late CharacterizationGameRepository repository;
  late GameCubit cubit;

  setUp(() {
    repository = CharacterizationGameRepository();
    cubit = GameCubit(
      getGameState: GetGameState(repository: repository),
      submitHint: SubmitHint(repository),
      submitVote: SubmitVote(repository),
      advanceToVoting: AdvanceToVoting(repository),
      finalizeVotingUseCase: FinalizeVoting(repository),
      createNextRound: CreateNextRound(repository),
      finishGameUseCase: FinishGame(repository),
      extendLocalRoleReveal: ExtendLocalRoleReveal(repository),
      gameRepository: repository,
      timeSyncService: TimeSyncService(FixedServerClock()),
    );
    cubit.emit(GameLoaded(phase2GameState()));
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
    await repository.dispose();
  });

  test('hint command delegates once and preserves loaded state', () async {
    await cubit.sendHint(
      roundId: 'round-1',
      playerId: 'host-player',
      hint: 'striped',
    );

    expect(repository.hintCalls, 1);
    expect(cubit.state, isA<GameLoaded>());
  });

  test('vote command delegates once for a different player', () async {
    await cubit.sendVote(
      roundId: 'round-1',
      voterId: 'host-player',
      votedPlayerId: 'guest-player',
    );

    expect(repository.voteCalls, 1);
    expect(cubit.state, isA<GameLoaded>());
  });

  test('concurrent finalization requests are coalesced by round id', () async {
    repository.finalizeGate = Completer<void>();

    final first = cubit.finalizeVoting('round-1', 'all_votes');
    final second = cubit.finalizeVoting('round-1', 'all_votes');
    repository.finalizeGate!.complete();
    await Future.wait([first, second]);

    expect(repository.finalizeCalls, 1);
    expect(
      (cubit.state as GameLoaded).gameState.playerScores['host-player'],
      2,
    );
  });

  test('next round command replaces current round on success', () async {
    final succeeded = await cubit.createNewRound(
      roomId: 'room-1',
      roundNumber: 2,
    );

    expect(succeeded, isTrue);
    expect(repository.nextRoundCalls, 1);
    expect((cubit.state as GameLoaded).gameState.currentRound.roundNumber, 2);
  });

  test('finish command emits current GameEnded behavior', () async {
    await cubit.finishGame('room-1');

    expect(repository.finishCalls, 1);
    expect(cubit.state, isA<GameEnded>());
  });

  test('online game owns exactly three replaceable session streams', () async {
    await cubit.loadGameState(roomId: 'room-1', currentPlayerId: 'host-user');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.activeOnlineGameSubscriptionCount, 3);

    await cubit.refreshGameStateOnResume(roomId: 'room-1', maxRetries: 1);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.activeOnlineGameSubscriptionCount, 3);

    await cubit.close();
    expect(cubit.activeOnlineGameSubscriptionCount, 0);
  });

  test('repeated finished room updates emit game end exactly once', () async {
    await cubit.loadGameState(roomId: 'room-1', currentPlayerId: 'host-user');
    await Future<void>.delayed(Duration.zero);
    final endedStates = <GameEnded>[];
    final subscription = cubit.stream.listen((state) {
      if (state is GameEnded) endedStates.add(state);
    });

    repository.roomStatusController.add('finished');
    repository.roomStatusController.add('finished');
    await Future<void>.delayed(Duration.zero);

    expect(endedStates, hasLength(1));
    await subscription.cancel();
  });

  test(
    'presence stream replaces host authority from repository state',
    () async {
      await cubit.createNewRound(roomId: 'room-1', roundNumber: 2);
      const migrated = <Player>[
        Player(
          id: 'host-player',
          roomId: 'room-1',
          userId: 'host-user',
          username: 'Former Host',
          score: 0,
          isHost: false,
          isOnline: true,
        ),
        Player(
          id: 'guest-player',
          roomId: 'room-1',
          userId: 'guest-user',
          username: 'New Host',
          score: 0,
          isHost: true,
          isOnline: true,
        ),
      ];

      repository.playersController.add(migrated);
      await Future<void>.delayed(Duration.zero);

      final players = (cubit.state as GameLoaded).gameState.players;
      expect(players.singleWhere((player) => player.isHost).id, 'guest-player');
      expect(
        players.singleWhere((player) => player.id == 'host-player').isHost,
        isFalse,
      );
    },
  );

  test(
    'closing cubit cancels presence subscription before late events',
    () async {
      await cubit.createNewRound(roomId: 'room-1', roundNumber: 2);
      final states = <GameState>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.close();
      final before = states.length;

      repository.playersController.add(phase2Players);
      await Future<void>.delayed(Duration.zero);

      expect(states.length, before);
      await subscription.cancel();
    },
  );
}

class FixedServerClock implements ServerClock {
  @override
  Future<DateTime> getServerTime() async => DateTime.utc(2026, 7, 13);
}

class CharacterizationGameRepository implements GameRepository {
  int hintCalls = 0;
  int voteCalls = 0;
  int finalizeCalls = 0;
  int nextRoundCalls = 0;
  int finishCalls = 0;
  Completer<void>? finalizeGate;
  final playersController = StreamController<List<Player>>.broadcast();
  final roundsController = StreamController<RoundInfo>.broadcast();
  final roomStatusController = StreamController<String>.broadcast();

  Future<void> dispose() async {
    await playersController.close();
    await roundsController.close();
    await roomStatusController.close();
  }

  @override
  Future<Either<Failure, void>> submitHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    hintCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> submitVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    voteCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, FinalizeVotingResult>> finalizeVoting({
    required String roundId,
    required String reason,
  }) async {
    finalizeCalls++;
    await finalizeGate?.future;
    return const Right(
      FinalizeVotingResult(
        roundId: 'round-1',
        phase: 'results',
        scores: {'host-player': 2},
        alreadyFinalized: false,
      ),
    );
  }

  @override
  Future<Either<Failure, RoundInfo>> createNextRound({
    required String roomId,
    required int expectedRoundNumber,
  }) async {
    nextRoundCalls++;
    return Right(phase2Round(id: 'round-2', roundNumber: 2));
  }

  @override
  Future<Either<Failure, void>> finishGame({required String roomId}) async {
    finishCalls++;
    return const Right(null);
  }

  @override
  Future<Either<Failure, RoundInfo>> advanceToVoting({
    required String roundId,
  }) async => Right(phase2Round(phase: GamePhase.voting));
  @override
  Future<Either<Failure, void>> extendLocalRoleReveal({
    required String roundId,
    required int seconds,
  }) async => const Right(null);
  @override
  Future<Either<Failure, entity.GameState>> getGameState({
    required String roomId,
    required String currentPlayerId,
  }) async => Right(phase2GameState());
  @override
  Future<Either<Failure, RoundInfo>> getCurrentRound({
    required String roomId,
  }) async => Right(phase2Round());
  @override
  Future<Either<Failure, LocalRoleRevealBundle>> getLocalRoleRevealBundle({
    required String roundId,
  }) async => Left(const ServerFailure('unused'));
  @override
  Future<Either<Failure, LocalRoleRevealData>> getLocalRoleRevealData({
    required String roomId,
  }) async => Left(const ServerFailure('unused'));
  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) =>
      playersController.stream;
  @override
  Stream<RoundInfo> watchRoundUpdates({required String roundId}) =>
      roundsController.stream;
  @override
  Stream<String> watchRoomStatus({required String roomId}) =>
      roomStatusController.stream;
  @override
  Future<Either<Failure, void>> updateCurrentPlayerPresence({
    required String roomId,
    required String userId,
    required bool isOnline,
  }) async => const Right(null);
}

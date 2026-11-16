import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/countdown_cubit.dart';

import '../../../../helpers/game_test_fixtures.dart';

class _FakeGameRepository implements GameRepository {
  final List<Future<Either<Failure, RoundInfo>> Function()> script;
  int calls = 0;

  _FakeGameRepository(this.script);

  @override
  Future<Either<Failure, RoundInfo>> getCurrentRound({required String roomId}) {
    final index = calls < script.length ? calls : script.length - 1;
    calls++;
    return script[index]();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRoomRepository implements RoomRepository {
  final String gameMode;
  final bool fail;

  _FakeRoomRepository([this.gameMode = 'online', this.fail = false]);

  @override
  ResultFuture<Room> getRoomDetails({required String roomId}) async => fail
      ? const Left(ServerFailure('net', code: AppErrorCode.network))
      : Right(
          Room(
            id: roomId,
            hostId: 'host-1',
            category: 'movies',
            maxRounds: 5,
            currentRound: 0,
            roomCode: '123456',
            status: 'active',
            usedCharacterIds: const [],
            maxPlayers: 6,
            roundDuration: 60,
            gameMode: gameMode,
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Either<Failure, RoundInfo>> _found() async => Right(phase2Round());
Future<Either<Failure, RoundInfo>> _missing() async =>
    const Left(ServerFailure('no round', code: AppErrorCode.roundNotFound));

CountdownCubit _cubit(
  _FakeGameRepository repo, {
  String gameMode = 'online',
  int maxAttempts = 3,
  bool roomLookupFails = false,
}) => CountdownCubit(
  gameRepository: repo,
  roomRepository: _FakeRoomRepository(gameMode, roomLookupFails),
  roomId: 'room-1',
  maxAttempts: maxAttempts,
  pollInterval: const Duration(milliseconds: 1),
);

void main() {
  test('round found on first try emits ready', () async {
    final repo = _FakeGameRepository([_found]);
    final cubit = _cubit(repo);
    final states = <CountdownState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.resolveRound();
    await Future<void>.delayed(Duration.zero);

    expect(repo.calls, 1);
    expect(states.last, const CountdownReady('online'));
    await sub.cancel();
    await cubit.close();
  });

  test('local game mode is reported on ready', () async {
    final cubit = _cubit(_FakeGameRepository([_found]), gameMode: 'local');
    await cubit.resolveRound();
    expect(cubit.state, isA<CountdownReady>());
    expect((cubit.state as CountdownReady).isLocal, isTrue);
    await cubit.close();
  });

  test('room lookup failure never guesses a game mode', () async {
    final cubit = _cubit(
      _FakeGameRepository([_found]),
      gameMode: 'local',
      roomLookupFails: true,
    );
    await cubit.resolveRound();
    expect(cubit.state, const CountdownRoundUnavailable(AppErrorCode.network));
    await cubit.close();
  });

  test('round found after retries emits ready', () async {
    final repo = _FakeGameRepository([_missing, _missing, _found]);
    final cubit = _cubit(repo);

    await cubit.resolveRound();

    expect(repo.calls, 3);
    expect(cubit.state, isA<CountdownReady>());
    await cubit.close();
  });

  test('thrown errors count as failed attempts', () async {
    final repo = _FakeGameRepository([
      () async => throw Exception('SocketException: failed host lookup'),
      _found,
    ]);
    final cubit = _cubit(repo);

    await cubit.resolveRound();

    expect(cubit.state, isA<CountdownReady>());
    await cubit.close();
  });

  test('never found emits roundUnavailable with the last code', () async {
    final repo = _FakeGameRepository([_missing]);
    final cubit = _cubit(repo);

    await cubit.resolveRound();

    expect(repo.calls, 3);
    expect(
      cubit.state,
      const CountdownRoundUnavailable(AppErrorCode.roundNotFound),
    );
    await cubit.close();
  });

  test('retry recovers after roundUnavailable', () async {
    final repo = _FakeGameRepository([_missing, _missing, _missing, _found]);
    final cubit = _cubit(repo);

    await cubit.resolveRound();
    expect(cubit.state, isA<CountdownRoundUnavailable>());

    await cubit.resolveRound();
    expect(cubit.state, isA<CountdownReady>());
    await cubit.close();
  });

  test('closing during polling does not emit', () async {
    final completer = Completer<Either<Failure, RoundInfo>>();
    final repo = _FakeGameRepository([() => completer.future]);
    final cubit = _cubit(repo);
    final states = <CountdownState>[];
    final sub = cubit.stream.listen(states.add);

    final pending = cubit.resolveRound();
    await Future<void>.delayed(Duration.zero);
    await cubit.close();
    completer.complete(Right(phase2Round()));

    await expectLater(pending, completes);
    expect(states.whereType<CountdownReady>(), isEmpty);
    expect(states.whereType<CountdownRoundUnavailable>(), isEmpty);
    await sub.cancel();
  });
}

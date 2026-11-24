import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

void main() {
  late FakeRoomRepository repository;
  late RoomCubit cubit;

  setUp(() {
    repository = FakeRoomRepository();
    cubit = RoomCubit(
      repository: repository,
      pollFallbackInterval: const Duration(milliseconds: 20),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test(
    'roster that arrives before the room details is not lost (stuck "Syncing your player")',
    () async {
      final players = [player()];
      repository.currentPlayers = players;

      // Same order as the waiting-room route: load starts, the watch starts,
      // and the players stream answers before the room details request.
      cubit.emit(RoomLoading());
      await cubit.watchRoomStatus(roomId: 'room-1');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await cubit.loadRoomDetails(roomId: 'room-1');

      final loaded = cubit.state as RoomDetailsLoaded;
      expect(loaded.players, players);
    },
  );

  test('watchRoomStatus emits active room and preserves players', () async {
    final waitingRoom = roomWithStatus('waiting');
    final activeRoom = roomWithStatus('active');
    final players = [player()];
    repository.currentPlayers = players;

    cubit.emit(RoomDetailsLoaded(waitingRoom, players: players));

    final states = <RoomState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.watchRoomStatus(roomId: waitingRoom.id);
    repository.emitRoom(activeRoom);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(states.last, isA<RoomDetailsLoaded>());
    final loaded = states.last as RoomDetailsLoaded;
    expect(loaded.room.status, 'active');
    expect(loaded.players, players);

    await subscription.cancel();
  });

  test(
    'watchRoomStatus emits initial active room from current room fetch',
    () async {
      final activeRoom = roomWithStatus('active');
      repository.currentRoom = activeRoom;

      final states = <RoomState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.watchRoomStatus(roomId: activeRoom.id);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.whereType<RoomDetailsLoaded>().last.room.status, 'active');

      await subscription.cancel();
    },
  );

  test(
    'close cancels watcher resources and ignores later stream events',
    () async {
      final waitingRoom = roomWithStatus('waiting');
      repository.currentRoom = waitingRoom;

      final states = <RoomState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.watchRoomStatus(roomId: waitingRoom.id);
      await cubit.close();
      final emittedBeforeLateUpdate = states.length;

      repository.emitRoom(roomWithStatus('active'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(states.length, emittedBeforeLateUpdate);

      await subscription.cancel();
    },
  );

  test('loadRoomDetails after close does not throw or emit', () async {
    await cubit.close();

    await cubit.loadRoomDetails(roomId: 'room-1');

    expect(cubit.state, isA<RoomInitial>());
  });

  test('loadRoomDetails closed mid-request does not throw', () async {
    final pending = cubit.loadRoomDetails(roomId: 'room-1');
    await cubit.close();

    await expectLater(pending, completes);
  });

  test('room poll does not run while streams are healthy', () async {
    await cubit.watchRoomStatus(roomId: 'room-1');
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(repository.detailsCalls, 0);
    expect(repository.playersCalls, 0);
  });

  test('room poll starts after a stream error and stops on recovery', () async {
    await cubit.watchRoomStatus(roomId: 'room-1');
    repository.emitRoomError();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(repository.detailsCalls, greaterThan(0));
    expect(repository.playersCalls, greaterThan(0));

    repository.emitRoom(roomWithStatus('waiting'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final callsAfterRecovery = repository.detailsCalls;
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(repository.detailsCalls, callsAfterRecovery);
  });

  test('waiting room owns exactly two replaceable session streams', () async {
    await cubit.watchRoomStatus(roomId: 'room-1');
    expect(cubit.activeSessionSubscriptionCount, 2);

    await cubit.watchRoomStatus(roomId: 'room-1');
    expect(cubit.activeSessionSubscriptionCount, 2);

    await cubit.close();
    expect(cubit.activeSessionSubscriptionCount, 0);
  });

  test(
    'create room captures current command shape and emits session',
    () async {
      await cubit.createNewRoom(
        category: 'animals',
        maxRounds: 3,
        username: 'Host',
        maxPlayers: 4,
        roundDuration: 60,
        gameMode: 'online',
      );

      expect(repository.createCalls, 1);
      expect(repository.lastCreateCategory, 'animals');
      expect(repository.lastCreateGameMode, 'online');
      expect(cubit.state, isA<RoomWithPlayerCreated>());
    },
  );

  RematchSeed rematchSeed({
    String gameMode = 'online',
    List<String> localNames = const [],
  }) => RematchSeed(
    previousRoomId: 'room-0',
    gameMode: gameMode,
    category: 'movies',
    maxRounds: 5,
    maxPlayers: 6,
    roundDuration: 60,
    localNames: localNames,
  );

  test('createRematch online emits session and sends the username', () async {
    final states = <RoomState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.createRematch(
      seed: rematchSeed(),
      category: 'animals',
      maxRounds: 3,
      maxPlayers: 4,
      roundDuration: 30,
      username: 'Host',
      localPlayerNames: const ['ignored'],
    );
    await Future<void>.delayed(Duration.zero);

    expect(repository.rematchCalls, 1);
    expect(repository.lastRematchPreviousRoomId, 'room-0');
    expect(repository.lastRematchHost, 'Host');
    expect(repository.lastRematchLocalNames, isEmpty);
    expect(states.first, isA<RoomLoading>());
    expect(states.last, isA<RoomWithPlayerCreated>());
    await sub.cancel();
  });

  test('createRematch local sends first name as host and the rest', () async {
    await cubit.createRematch(
      seed: rematchSeed(gameMode: 'local'),
      category: 'movies',
      maxRounds: 5,
      maxPlayers: 6,
      roundDuration: 60,
      username: 'Ignored',
      localPlayerNames: const ['Ann', 'Bob', 'Cy'],
    );

    expect(repository.lastRematchHost, 'Ann');
    expect(repository.lastRematchLocalNames, ['Bob', 'Cy']);
    expect(cubit.state, isA<RoomWithPlayerCreated>());
  });

  test('createRematch failure emits RoomError and retry reuses id', () async {
    repository.rematchFailure = const ServerFailure(
      'ROOM_NOT_FINISHED',
      code: AppErrorCode.roomNotFinished,
    );
    Future<void> create() => cubit.createRematch(
      seed: rematchSeed(),
      category: 'movies',
      maxRounds: 5,
      maxPlayers: 6,
      roundDuration: 60,
      username: 'Host',
    );

    await create();
    expect(cubit.state, const RoomError(AppErrorCode.roomNotFinished));
    final firstId = repository.lastRematchRequestId;

    await create();
    expect(repository.lastRematchRequestId, firstId);

    repository.rematchFailure = null;
    await create();
    expect(repository.lastRematchRequestId, firstId);
    expect(cubit.state, isA<RoomWithPlayerCreated>());
  });

  test('start validation failure currently becomes RoomError', () async {
    repository.startFailure = const ServerFailure(
      'NOT_ENOUGH_PLAYERS',
      code: AppErrorCode.notEnoughPlayers,
    );

    await cubit.startGameSession('room-1');

    expect(repository.startCalls, 1);
    expect(cubit.state, const RoomError(AppErrorCode.notEnoughPlayers));
  });

  test(
    'presence heartbeat delegates online status with player identity',
    () async {
      await cubit.setPlayerStatus(playerId: 'player-1', isOnline: true);

      expect(repository.statusUpdates, [('player-1', true)]);
    },
  );

  test('formal leave delegates once without changing visible state', () async {
    final before = cubit.state;

    await cubit.leaveRoomSession(
      playerId: 'player-1',
      roomId: 'room-1',
      isHost: true,
    );

    expect(repository.leaveCalls, 1);
    expect(cubit.state, same(before));
  });

  test(
    'online room invokes stale cleanup and shared-device room skips it',
    () async {
      cubit.emit(RoomDetailsLoaded(roomWithStatus('waiting')));
      await cubit.cleanUpStalePlayers(roomId: 'room-1', staleSeconds: 90);
      expect(repository.cleanupCalls, 1);

      cubit.emit(
        RoomDetailsLoaded(
          Room(
            id: 'room-1',
            hostId: 'host-1',
            category: 'animals',
            maxRounds: 3,
            currentRound: 0,
            roomCode: '123456',
            status: 'waiting',
            usedCharacterIds: const [],
            maxPlayers: 4,
            roundDuration: 60,
            gameMode: 'local',
          ),
        ),
      );
      await cubit.cleanUpStalePlayers(roomId: 'room-1', staleSeconds: 90);
      expect(repository.cleanupCalls, 1);
    },
  );
}

class FakeRoomRepository implements RoomRepository {
  final StreamController<Room> _controller = StreamController<Room>.broadcast();
  final StreamController<List<Player>> _playersController =
      StreamController<List<Player>>.broadcast();
  Room currentRoom = roomWithStatus('waiting');
  List<Player> currentPlayers = const <Player>[];
  int createCalls = 0;
  int startCalls = 0;
  String? lastCreateCategory;
  String? lastCreateGameMode;
  int rematchCalls = 0;
  String? lastRematchRequestId;
  String? lastRematchPreviousRoomId;
  String? lastRematchHost;
  List<String>? lastRematchLocalNames;
  Failure? rematchFailure;
  Failure? startFailure;
  int cleanupCalls = 0;
  int leaveCalls = 0;
  int detailsCalls = 0;
  int playersCalls = 0;
  final List<(String, bool)> statusUpdates = [];

  void emitRoomError() => _controller.addError(StateError('stream down'));

  void emitRoom(Room room) {
    currentRoom = room;
    _controller.add(room);
  }

  Future<void> dispose() async {
    await _controller.close();
    await _playersController.close();
  }

  @override
  ResultFuture<RoomSession> createRoom({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  }) async {
    createCalls++;
    lastCreateCategory = category;
    lastCreateGameMode = gameMode;
    final currentPlayer = player();
    return Right(
      RoomSession(
        room: currentRoom,
        currentPlayer: currentPlayer,
        players: [currentPlayer],
      ),
    );
  }

  @override
  ResultFuture<RoomSession> createRematch({
    required String requestId,
    required String previousRoomId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String hostUsername,
    required List<String> localNames,
  }) async {
    rematchCalls++;
    lastRematchRequestId = requestId;
    lastRematchPreviousRoomId = previousRoomId;
    lastRematchHost = hostUsername;
    lastRematchLocalNames = localNames;
    if (rematchFailure case final failure?) return Left(failure);
    final currentPlayer = player();
    return Right(
      RoomSession(
        room: currentRoom,
        currentPlayer: currentPlayer,
        players: [currentPlayer],
      ),
    );
  }

  @override
  ResultFuture<RoomSession?> respondToRematchInvite({
    required String roomId,
    required bool accept,
  }) async => const Right(null);

  @override
  Stream<List<RoomInvite>> watchRoomInvites({required String roomId}) =>
      const Stream.empty();

  @override
  Stream<List<RoomInvite>> watchMyRematchInvites({
    required String previousRoomId,
    required String userId,
  }) => const Stream.empty();

  @override
  ResultFuture<RoomSession> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    final currentPlayer = player();
    return Right(
      RoomSession(
        room: currentRoom,
        currentPlayer: currentPlayer,
        players: [currentPlayer],
      ),
    );
  }

  @override
  ResultFuture<Room> getRoomDetails({required String roomId}) async {
    detailsCalls++;
    return Right(currentRoom);
  }

  @override
  ResultFuture<List<Player>> getRoomPlayers({required String roomId}) async {
    playersCalls++;
    return const Right([]);
  }

  @override
  ResultFuture<void> leaveRoom({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    leaveCalls++;
    return const Right(null);
  }

  @override
  ResultFuture<void> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  }) async {
    cleanupCalls++;
    return const Right(null);
  }

  @override
  ResultFuture<String> startGame(String roomId) async {
    startCalls++;
    if (startFailure case final failure?) return Left(failure);
    return const Right('round-1');
  }

  @override
  ResultFuture<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
    statusUpdates.add((playerId, isOnline));
    return const Right(null);
  }

  @override
  Stream<Room> watchRoomDetails({required String roomId}) {
    return Stream.multi((multi) {
      multi.add(currentRoom);
      final subscription = _controller.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = subscription.cancel;
    });
  }

  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) {
    return Stream.multi((multi) {
      multi.add(currentPlayers);
      final subscription = _playersController.stream.listen(
        multi.add,
        onError: multi.addError,
        onDone: multi.close,
      );
      multi.onCancel = subscription.cancel;
    });
  }
}

Room roomWithStatus(String status) {
  return Room(
    id: 'room-1',
    hostId: 'host-1',
    category: 'movies',
    maxRounds: 5,
    currentRound: 0,
    roomCode: '123456',
    status: status,
    usedCharacterIds: const [],
    maxPlayers: 6,
    roundDuration: 60,
    gameMode: 'online',
  );
}

Player player() {
  return const Player(
    id: 'player-1',
    roomId: 'room-1',
    userId: 'user-1',
    username: 'User',
    score: 0,
    isHost: false,
  );
}

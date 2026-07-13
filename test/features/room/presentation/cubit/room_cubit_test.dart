import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/join_room.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_players.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

void main() {
  late FakeRoomRepository repository;
  late RoomCubit cubit;

  setUp(() {
    repository = FakeRoomRepository();
    cubit = RoomCubit(
      createRoom: CreateRoom(repository),
      getRoomDetails: GetRoomDetails(repository),
      getRoomPlayers: GetRoomPlayers(repository),
      getRoomByCode: GetRoomByCode(repository),
      startGame: StartGame(repository),
      updatePlayerStatus: UpdatePlayerStatus(repository),
      markStalePlayersOffline: MarkStalePlayersOffline(repository),
      leaveRoom: LeaveRoom(repository),
      joinRoomCommand: JoinRoom(repository),
      watchRoomDetails: WatchRoomDetails(repository),
      watchRoomPlayers: WatchRoomPlayers(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

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

  test('start validation failure currently becomes RoomError', () async {
    repository.startFailure = const ServerFailure('NOT_ENOUGH_PLAYERS');

    await cubit.startGameSession('room-1');

    expect(repository.startCalls, 1);
    expect(cubit.state, const RoomError('NOT_ENOUGH_PLAYERS'));
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
  Failure? startFailure;
  int cleanupCalls = 0;
  int leaveCalls = 0;
  final List<(String, bool)> statusUpdates = [];

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
  ResultFuture<Room> getRoomByCode({required String roomCode}) async {
    return Right(currentRoom);
  }

  @override
  ResultFuture<Room> getRoomDetails({required String roomId}) async {
    return Right(currentRoom);
  }

  @override
  ResultFuture<List<Player>> getRoomPlayers({required String roomId}) async {
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

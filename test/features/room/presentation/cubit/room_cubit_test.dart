import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/domain/usecases/add_player_to_room.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_details.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

void main() {
  late FakeRoomRepository repository;
  late RoomCubit cubit;

  setUp(() {
    repository = FakeRoomRepository();
    cubit = RoomCubit(
      createRoom: CreateRoom(repository),
      addPlayerToRoom: AddPlayerToRoom(repository),
      getRoomDetails: GetRoomDetails(repository),
      getRoomPlayers: GetRoomPlayers(repository),
      getRoomByCode: GetRoomByCode(repository),
      startGame: StartGame(repository),
      updatePlayerStatus: UpdatePlayerStatus(repository),
      markStalePlayersOffline: MarkStalePlayersOffline(repository),
      leaveRoom: LeaveRoom(repository),
      watchRoomDetails: WatchRoomDetails(repository),
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

    cubit.emit(
      RoomDetailsLoaded(
        waitingRoom,
        players: players,
      ),
    );

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

  test('watchRoomStatus emits initial active room from current room fetch', () async {
    final activeRoom = roomWithStatus('active');
    repository.currentRoom = activeRoom;

    final states = <RoomState>[];
    final subscription = cubit.stream.listen(states.add);

    await cubit.watchRoomStatus(roomId: activeRoom.id);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(states.whereType<RoomDetailsLoaded>().last.room.status, 'active');

    await subscription.cancel();
  });

  test('close cancels watcher resources and ignores later stream events', () async {
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
  });
}

class FakeRoomRepository implements RoomRepository {
  final StreamController<Room> _controller = StreamController<Room>.broadcast();
  Room currentRoom = roomWithStatus('waiting');

  void emitRoom(Room room) {
    currentRoom = room;
    _controller.add(room);
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  ResultFuture<Player> addPlayerToRoom({
    required String roomId,
    required String username,
    required bool isHost,
    bool isLocalPlayer = false,
  }) async {
    return Right(
      Player(
        id: 'player-1',
        roomId: roomId,
        userId: 'user-1',
        username: username,
        score: 0,
        isHost: isHost,
      ),
    );
  }

  @override
  ResultFuture<Room> createRoom({
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
  }) async {
    return Right(currentRoom);
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
    return const Right(null);
  }

  @override
  ResultFuture<void> markStalePlayersOffline({required int staleSeconds}) async {
    return const Right(null);
  }

  @override
  ResultFuture<void> startGame(String roomId) async {
    return const Right(null);
  }

  @override
  ResultFuture<void> updatePlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
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

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/core/theme/app_theme.dart';
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
import 'package:guess_party/features/room/presentation/views/waiting_room_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigates once to countdown when room becomes active', (
    tester,
  ) async {
    final cubit = TestRoomCubit();
    var countdownBuilds = 0;
    final router = GoRouter(
      initialLocation: '/room/room-1/waiting',
      routes: [
        GoRoute(
          path: '/room/:roomId/waiting',
          builder: (context, state) => WaitingRoomView(
            roomId: state.pathParameters['roomId']!,
            roomCubit: cubit,
            currentUserIdResolver: () => null,
            playersListBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
        GoRoute(
          path: '/room/:roomId/countdown',
          builder: (context, state) {
            countdownBuilds++;
            return const Scaffold(body: Text('Countdown'));
          },
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router, theme: AppTheme.darkTheme),
    );

    cubit.emitState(
      RoomDetailsLoaded(roomWithStatus('active'), players: const []),
    );
    await tester.pumpAndSettle();

    cubit.emitState(
      RoomDetailsLoaded(roomWithStatus('active'), players: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text('Countdown'), findsOneWidget);
    expect(countdownBuilds, 1);

    await cubit.close();
  });
}

class TestRoomCubit extends RoomCubit {
  TestRoomCubit() : this._(FakeRoomRepository());

  TestRoomCubit._(FakeRoomRepository repository)
    : super(
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

  void emitState(RoomState state) {
    emit(state);
  }
}

class FakeRoomRepository implements RoomRepository {
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
    final room = roomWithStatus('waiting');
    final currentPlayer = player(room.id);
    return Right(
      RoomSession(
        room: room,
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
    final room = roomWithStatus('waiting');
    final currentPlayer = player(room.id);
    return Right(
      RoomSession(
        room: room,
        currentPlayer: currentPlayer,
        players: [currentPlayer],
      ),
    );
  }

  @override
  ResultFuture<Room> getRoomByCode({required String roomCode}) async {
    return Right(roomWithStatus('waiting'));
  }

  @override
  ResultFuture<Room> getRoomDetails({required String roomId}) async {
    return Right(roomWithStatus('waiting'));
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
  ResultFuture<void> markStalePlayersOffline({
    required String roomId,
    required int staleSeconds,
  }) async {
    return const Right(null);
  }

  @override
  ResultFuture<String> startGame(String roomId) async {
    return const Right('round-1');
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
    return const Stream.empty();
  }

  @override
  Stream<List<Player>> watchRoomPlayers({required String roomId}) {
    return const Stream.empty();
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

Player player(String roomId) {
  return Player(
    id: 'player-1',
    roomId: roomId,
    userId: 'user-1',
    username: 'Host',
    score: 0,
    isHost: true,
  );
}

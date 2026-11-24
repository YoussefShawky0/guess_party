import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/core/theme/app_theme.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
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
          builder: (context, state) => BlocProvider<RoomCubit>.value(
            value: cubit,
            child: WaitingRoomView(
              roomId: state.pathParameters['roomId']!,
              currentUserIdResolver: () => null,
              playersListBuilder: (_) => const SizedBox.shrink(),
            ),
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
    : super(repository: repository);

  void emitState(RoomState state) {
    emit(state);
  }
}

class FakeRoomRepository implements RoomRepository {
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
  }) async => throw UnimplementedError();

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

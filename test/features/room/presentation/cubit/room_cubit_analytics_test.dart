import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

import '../../../../helpers/recording_analytics.dart';
import 'room_cubit_test.dart' show FakeRoomRepository;

void main() {
  late FakeRoomRepository repository;
  late RecordingAnalytics analytics;
  late RoomCubit cubit;

  setUp(() {
    repository = FakeRoomRepository();
    analytics = RecordingAnalytics();
    cubit = RoomCubit(repository: repository, analytics: analytics);
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test(
    'room_created logs mode and category after the server succeeds',
    () async {
      await cubit.createNewRoom(
        category: 'movies',
        maxRounds: 3,
        username: 'Host',
        maxPlayers: 6,
        roundDuration: 60,
        gameMode: 'online',
      );

      final event = analytics.events.single as RoomCreatedEvent;
      expect(event.params, {'mode': 'online', 'category': 'movies'});
    },
  );

  test('room_joined logs with no params after a successful join', () async {
    await cubit.joinRoom(roomCode: '123456', username: 'Me');
    expect(analytics.events.single, isA<RoomJoinedEvent>());
    expect(analytics.events.single.params, isEmpty);
  });

  test('rematch_started logs the seed mode', () async {
    await cubit.createRematch(
      seed: const RematchSeed(
        previousRoomId: 'old',
        gameMode: 'local',
        category: 'movies',
        maxRounds: 3,
        maxPlayers: 6,
        roundDuration: 60,
        localNames: ['A', 'B'],
      ),
      category: 'movies',
      maxRounds: 3,
      maxPlayers: 6,
      roundDuration: 60,
      username: 'Host',
      localPlayerNames: const ['A', 'B'],
    );

    final event = analytics.events.single as RematchStartedEvent;
    expect(event.params, {'mode': 'local'});
  });

  test('a failed rematch logs nothing', () async {
    repository.rematchFailure = const ServerFailure(
      'ROOM_NOT_FINISHED',
      code: AppErrorCode.roomNotFinished,
    );
    await cubit.createRematch(
      seed: const RematchSeed(
        previousRoomId: 'old',
        gameMode: 'online',
        category: 'movies',
        maxRounds: 3,
        maxPlayers: 6,
        roundDuration: 60,
        localNames: [],
      ),
      category: 'movies',
      maxRounds: 3,
      maxPlayers: 6,
      roundDuration: 60,
      username: 'Host',
    );

    expect(analytics.events, isEmpty);
  });
}

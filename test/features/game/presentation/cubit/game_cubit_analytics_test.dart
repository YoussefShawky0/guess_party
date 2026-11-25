import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

import '../../../../helpers/game_test_fixtures.dart';
import '../../../../helpers/recording_analytics.dart';
import 'game_cubit_characterization_test.dart'
    show CharacterizationGameRepository, FixedServerClock;

void main() {
  late CharacterizationGameRepository repository;
  late RecordingAnalytics analytics;
  late GameCubit cubit;

  setUp(() {
    repository = CharacterizationGameRepository();
    analytics = RecordingAnalytics();
    cubit = GameCubit(
      gameRepository: repository,
      timeSyncService: TimeSyncService(FixedServerClock()),
      analytics: analytics,
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  test('game_started is logged once when round 1 loads', () async {
    await cubit.loadGameState(roomId: 'room-1', currentPlayerId: 'host-user');
    await cubit.loadGameState(roomId: 'room-1', currentPlayerId: 'host-user');

    final started = analytics.events.whereType<GameStartedEvent>().toList();
    expect(started, hasLength(1));
    expect(started.single.mode, 'online');
    expect(started.single.players, 2);
    expect(started.single.rounds, 3);
  });

  test('game_started is not logged when a later round loads', () async {
    cubit.emit(GameLoaded(phase2GameState()));
    await cubit.createNewRound(roomId: 'room-1', roundNumber: 2);

    expect(analytics.events, isEmpty);
  });

  test('game_finished is logged when finishing succeeds', () async {
    cubit.emit(GameLoaded(phase2GameState()));
    await cubit.finishGame('room-1');

    expect(analytics.events.single, isA<GameFinishedEvent>());
    expect((analytics.events.single as GameFinishedEvent).rounds, 3);
  });

  test('game_finished is logged for a finish seen via room status', () async {
    await cubit.loadGameState(roomId: 'room-1', currentPlayerId: 'host-user');
    await Future<void>.delayed(Duration.zero);
    repository.roomStatusController.add('finished');
    await Future<void>.delayed(Duration.zero);

    expect(analytics.names, ['game_started', 'game_finished']);
    expect(cubit.state, isA<GameEnded>());
  });

  test('game_finished is not logged when finishing fails', () async {
    repository.finishFailure = const ServerFailure('nope');
    cubit.emit(GameLoaded(phase2GameState()));
    await cubit.finishGame('room-1');

    expect(analytics.events, isEmpty);
  });

  test('game_left_early carries mode and phase only', () {
    cubit.emit(GameLoaded(phase2GameState()));
    cubit.trackLeftEarly();

    final event = analytics.events.single as GameLeftEarlyEvent;
    expect(event.params, {'mode': 'online', 'phase': 'hints'});
  });

  test('game_left_early is skipped without a loaded game', () {
    cubit.trackLeftEarly();
    expect(analytics.events, isEmpty);
  });
}

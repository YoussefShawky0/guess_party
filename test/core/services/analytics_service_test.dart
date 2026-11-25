import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/services/analytics_service.dart';

import '../../helpers/recording_analytics.dart';

void main() {
  const events = <AnalyticsEvent>[
    GameStartedEvent(mode: 'online', category: 'movies', players: 5, rounds: 3),
    GameFinishedEvent(mode: 'local', category: 'animals', rounds: 3),
    GameLeftEarlyEvent(mode: 'online', phase: 'voting'),
    RoomCreatedEvent(mode: 'online', category: 'movies'),
    RoomJoinedEvent(),
    RematchStartedEvent(mode: 'online'),
    RematchInviteAnsweredEvent(accepted: true),
    StatsViewedEvent(),
    BadgeUnlockedEvent(badge: 'champion'),
  ];

  test('event names are the documented snake_case names', () {
    expect(events.map((e) => e.name), [
      'game_started',
      'game_finished',
      'game_left_early',
      'room_created',
      'room_joined',
      'rematch_started',
      'rematch_invite_answered',
      'stats_viewed',
      'badge_unlocked',
    ]);
  });

  test('params have the documented keys', () {
    expect(events[0].params, {
      'mode': 'online',
      'category': 'movies',
      'players': 5,
      'rounds': 3,
    });
    expect(events[1].params.keys, {'mode', 'category', 'rounds'});
    expect(events[2].params, {'mode': 'online', 'phase': 'voting'});
    expect(events[3].params.keys, {'mode', 'category'});
    expect(events[4].params, isEmpty);
    expect(events[5].params, {'mode': 'online'});
    expect(events[6].params, {'accepted': 'true'});
    expect(events[7].params, isEmpty);
    expect(events[8].params, {'badge': 'champion'});
  });

  test('no event carries PII keys and values are String or num', () {
    const forbidden = {
      'username',
      'user_id',
      'userid',
      'room_code',
      'roomcode',
      'room_id',
      'roomid',
      'chat',
      'message',
      'character',
      'name',
      'player',
    };
    for (final event in events) {
      for (final entry in event.params.entries) {
        expect(forbidden.contains(entry.key.toLowerCase()), isFalse);
        expect(entry.value is String || entry.value is num, isTrue);
      }
    }
  });

  test('track never throws even when the service does', () {
    expect(
      () => ThrowingAnalytics().track(const RoomJoinedEvent()),
      returnsNormally,
    );
  });

  test('noop service accepts every event', () async {
    for (final event in events) {
      await const NoopAnalyticsService().log(event);
    }
  });
}

import 'dart:async';

/// Product analytics. Events carry no personal data: never add usernames,
/// room codes, user ids, chat text or character names to an event.
abstract class AnalyticsService {
  /// Never throws.
  Future<void> log(AnalyticsEvent event);
}

/// Used by tests, CI and builds without Firebase configuration.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> log(AnalyticsEvent event) async {}
}

extension AnalyticsTracking on AnalyticsService {
  /// Fire-and-forget [log] that can never throw into gameplay.
  void track(AnalyticsEvent event) {
    try {
      unawaited(log(event).catchError((Object _) {}));
    } catch (_) {
      // Analytics must never affect the game.
    }
  }
}

sealed class AnalyticsEvent {
  const AnalyticsEvent();

  String get name;

  /// Values are String or num only (Firebase restriction).
  Map<String, Object> get params => const {};
}

final class GameStartedEvent extends AnalyticsEvent {
  const GameStartedEvent({
    required this.mode,
    required this.category,
    required this.players,
    required this.rounds,
  });

  final String mode;
  final String category;
  final int players;
  final int rounds;

  @override
  String get name => 'game_started';

  @override
  Map<String, Object> get params => {
    'mode': mode,
    'category': category,
    'players': players,
    'rounds': rounds,
  };
}

final class GameFinishedEvent extends AnalyticsEvent {
  const GameFinishedEvent({
    required this.mode,
    required this.category,
    required this.rounds,
  });

  final String mode;
  final String category;
  final int rounds;

  @override
  String get name => 'game_finished';

  @override
  Map<String, Object> get params => {
    'mode': mode,
    'category': category,
    'rounds': rounds,
  };
}

final class GameLeftEarlyEvent extends AnalyticsEvent {
  const GameLeftEarlyEvent({required this.mode, required this.phase});

  final String mode;
  final String phase;

  @override
  String get name => 'game_left_early';

  @override
  Map<String, Object> get params => {'mode': mode, 'phase': phase};
}

final class RoomCreatedEvent extends AnalyticsEvent {
  const RoomCreatedEvent({required this.mode, required this.category});

  final String mode;
  final String category;

  @override
  String get name => 'room_created';

  @override
  Map<String, Object> get params => {'mode': mode, 'category': category};
}

final class RoomJoinedEvent extends AnalyticsEvent {
  const RoomJoinedEvent();

  @override
  String get name => 'room_joined';
}

final class RematchStartedEvent extends AnalyticsEvent {
  const RematchStartedEvent({required this.mode});

  final String mode;

  @override
  String get name => 'rematch_started';

  @override
  Map<String, Object> get params => {'mode': mode};
}

final class RematchInviteAnsweredEvent extends AnalyticsEvent {
  const RematchInviteAnsweredEvent({required this.accepted});

  final bool accepted;

  @override
  String get name => 'rematch_invite_answered';

  @override
  Map<String, Object> get params => {'accepted': accepted ? 'true' : 'false'};
}

final class StatsViewedEvent extends AnalyticsEvent {
  const StatsViewedEvent();

  @override
  String get name => 'stats_viewed';
}

final class BadgeUnlockedEvent extends AnalyticsEvent {
  const BadgeUnlockedEvent({required this.badge});

  /// The badge id name (for example `champion`), never a player value.
  final String badge;

  @override
  String get name => 'badge_unlocked';

  @override
  Map<String, Object> get params => {'badge': badge};
}

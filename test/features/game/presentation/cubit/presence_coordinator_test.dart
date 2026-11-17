import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/presentation/cubit/presence_coordinator.dart';

class _FakeTimer implements Timer {
  _FakeTimer(this.onTick);

  final void Function() onTick;
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled;

  @override
  int get tick => 0;
}

Player _player(
  String id, {
  String? userId,
  bool host = false,
  bool online = true,
}) => Player(
  id: id,
  roomId: 'room-1',
  userId: userId ?? 'user-$id',
  username: 'Name-$id',
  score: 0,
  isHost: host,
  isOnline: online,
);

void main() {
  late List<_FakeTimer> timers;
  late List<bool> presenceCalls;
  late int cleanupCalls;
  late List<Duration> intervals;
  late PresenceCoordinator coordinator;
  late List<PresenceNotice> notices;
  String? userId;

  PresenceCoordinator build({bool failing = false}) {
    return PresenceCoordinator(
      roomId: 'room-1',
      currentUserId: () => userId,
      setPresence:
          ({required roomId, required userId, required isOnline}) async {
            presenceCalls.add(isOnline);
            if (failing) throw StateError('boom');
          },
      cleanupStalePlayers: ({required roomId, required staleSeconds}) async {
        expect(staleSeconds, 90);
        cleanupCalls++;
        if (failing) throw StateError('boom');
      },
      timerFactory: (interval, onTick) {
        intervals.add(interval);
        final timer = _FakeTimer(onTick);
        timers.add(timer);
        return timer;
      },
    );
  }

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  setUp(() {
    timers = [];
    presenceCalls = [];
    cleanupCalls = 0;
    intervals = [];
    notices = [];
    userId = 'user-me';
    coordinator = build();
    coordinator.notices.listen(notices.add);
  });

  tearDown(() => coordinator.dispose());

  group('departure and host notices', () {
    test('no notice on the first snapshot', () async {
      coordinator.onPlayersUpdated([
        _player('a', host: true),
        _player('b'),
      ], notify: false);
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      await pump();
      expect(notices, isEmpty);
    });

    test('single departure emits one PlayersLeftNotice', () async {
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      await pump();

      expect(notices, hasLength(1));
      final notice = notices.single as PlayersLeftNotice;
      expect(notice.players.map((p) => p.id), ['b']);
      expect(notice.players.single.username, 'Name-b');
    });

    test(
      'offline flag counts as departure; repeat is not re-announced',
      () async {
        coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
        coordinator.onPlayersUpdated([
          _player('a', host: true),
          _player('b', online: false),
        ]);
        coordinator.onPlayersUpdated([_player('a', host: true)]);
        await pump();
        expect(notices, hasLength(1));
      },
    );

    test('multiple departures are grouped in one notice', () async {
      coordinator.onPlayersUpdated([
        _player('a', host: true),
        _player('b'),
        _player('c'),
      ]);
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      await pump();

      final notice = notices.single as PlayersLeftNotice;
      expect(notice.players.map((p) => p.id), ['b', 'c']);
      expect(notice.dedupeKey, 'left:b|c');
    });

    test('the current user leaving is never announced', () async {
      coordinator.onPlayersUpdated([
        _player('a', host: true),
        _player('me', userId: 'user-me'),
      ]);
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      await pump();
      expect(notices, isEmpty);
    });

    test('a returning player can be announced again later', () async {
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      await pump();
      expect(notices.whereType<PlayersLeftNotice>(), hasLength(2));
    });

    test('host change emits NewHostNotice after the leave notice', () async {
      coordinator.onPlayersUpdated([
        _player('a', host: true),
        _player('b'),
        _player('c'),
      ]);
      coordinator.onPlayersUpdated([_player('b', host: true), _player('c')]);
      await pump();

      expect(notices, hasLength(2));
      expect(notices[0], isA<PlayersLeftNotice>());
      final host = notices[1] as NewHostNotice;
      expect(host.playerId, 'b');
      expect(host.username, 'Name-b');
      expect(host.dedupeKey, 'host:b');
    });

    test('no host notice when no online host remains', () async {
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      coordinator.onPlayersUpdated([_player('b')]);
      await pump();
      expect(notices.whereType<NewHostNotice>(), isEmpty);
    });
  });

  group('heartbeat and cleanup', () {
    test('nothing runs before start or in local mode', () async {
      coordinator.start();
      coordinator.setGameMode('local');
      coordinator.onResumed();
      coordinator.onBackgrounded();
      await pump();

      expect(presenceCalls, isEmpty);
      expect(cleanupCalls, 0);
      expect(timers, isEmpty);
      expect(coordinator.isRunning, isFalse);
    });

    test(
      'online start sends presence, cleanup and starts the heartbeat',
      () async {
        coordinator.setGameMode('online');
        coordinator.start();
        await pump();

        expect(presenceCalls, [true]);
        expect(cleanupCalls, 1);
        expect(intervals, [const Duration(seconds: 25)]);
      },
    );

    test('mode becoming online after start begins presence', () async {
      coordinator.start();
      expect(timers, isEmpty);
      coordinator.setGameMode('online');
      await pump();
      expect(presenceCalls, [true]);
      expect(timers, hasLength(1));
    });

    test('each tick sends presence and cleanup (no host gating)', () async {
      coordinator.setGameMode('online');
      coordinator.start();
      timers.single.onTick();
      timers.single.onTick();
      await pump();

      expect(presenceCalls, [true, true, true]);
      expect(cleanupCalls, 3);
    });

    test('resume re-sends presence, cleanup and restarts the timer', () async {
      coordinator.setGameMode('online');
      coordinator.start();
      coordinator.onBackgrounded();
      await pump();
      expect(presenceCalls, [true, false]);
      expect(timers.single.cancelled, isTrue);

      coordinator.onResumed();
      await pump();
      expect(presenceCalls, [true, false, true]);
      expect(cleanupCalls, 2);
      expect(timers, hasLength(2));
      expect(timers.last.cancelled, isFalse);
    });

    test('stop cancels the timer and ignores lifecycle events', () async {
      coordinator.setGameMode('online');
      coordinator.start();
      coordinator.stop();
      coordinator.onResumed();
      await pump();

      expect(timers.single.cancelled, isTrue);
      expect(presenceCalls, [true]);
      expect(cleanupCalls, 1);
    });

    test(
      'no presence calls without a signed-in user, cleanup still runs',
      () async {
        userId = null;
        coordinator.setGameMode('online');
        coordinator.start();
        await pump();
        expect(presenceCalls, isEmpty);
        expect(cleanupCalls, 1);
      },
    );

    test('repository failures are swallowed', () async {
      final failing = build(failing: true)..setGameMode('online');
      addTearDown(failing.dispose);
      failing.start();
      await pump();
      // Reaching here without an unhandled error is the assertion.
      expect(failing.isRunning, isTrue);
    });
  });

  group('dispose', () {
    test('cancels the timer and nothing runs or emits afterwards', () async {
      coordinator.setGameMode('online');
      coordinator.start();
      coordinator.onPlayersUpdated([_player('a', host: true), _player('b')]);
      await pump();
      final presenceBefore = presenceCalls.length;
      final cleanupBefore = cleanupCalls;

      coordinator.dispose();
      timers.single.onTick();
      coordinator.onResumed();
      coordinator.onBackgrounded();
      coordinator.start();
      coordinator.setGameMode('online');
      coordinator.onPlayersUpdated([_player('a', host: true)]);
      await pump();

      expect(timers.single.cancelled, isTrue);
      expect(presenceCalls.length, presenceBefore);
      expect(cleanupCalls, cleanupBefore);
      expect(notices, isEmpty);
    });
  });
}

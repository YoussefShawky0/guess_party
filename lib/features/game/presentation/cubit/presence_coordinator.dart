import 'dart:async';

import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';

/// Typed presence notices; the view layer localizes them.
sealed class PresenceNotice {
  const PresenceNotice();

  /// Stable key used by the view to suppress repeated banners.
  String get dedupeKey;
}

class DepartedPlayer {
  final String id;
  final String username;

  const DepartedPlayer({required this.id, required this.username});
}

/// One or more other players went offline since the previous snapshot.
class PlayersLeftNotice extends PresenceNotice {
  final List<DepartedPlayer> players;

  const PlayersLeftNotice(this.players);

  @override
  String get dedupeKey {
    final ids = players.map((p) => p.id).where((id) => id.isNotEmpty).toList()
      ..sort();
    return 'left:${ids.join('|')}';
  }
}

/// The online host changed to a different player.
class NewHostNotice extends PresenceNotice {
  final String playerId;
  final String username;

  const NewHostNotice({required this.playerId, required this.username});

  @override
  String get dedupeKey => 'host:$playerId';
}

typedef PresenceUpdate =
    Future<void> Function({
      required String roomId,
      required String userId,
      required bool isOnline,
    });

typedef StalePlayerCleanup =
    Future<void> Function({required String roomId, required int staleSeconds});

typedef PeriodicTimerFactory =
    Timer Function(Duration interval, void Function() onTick);

Timer _defaultTimerFactory(Duration interval, void Function() onTick) =>
    Timer.periodic(interval, (_) => onTick());

/// Plain-Dart presence logic for an online game screen: heartbeat, stale
/// cleanup and departure/new-host detection.
///
/// Nothing runs unless the coordinator is [start]ed AND the game mode is
/// online (shared-device mode never runs online presence). Every online player
/// runs stale cleanup on every heartbeat/start/resume (no host-only gating):
/// the server lets any online room member run it, so the room still heals when
/// the host's app is killed.
class PresenceCoordinator {
  static const Duration defaultHeartbeatInterval = Duration(seconds: 25);
  static const int defaultStaleSeconds = 90;

  final String roomId;
  final String? Function() currentUserId;
  final PresenceUpdate setPresence;
  final StalePlayerCleanup cleanupStalePlayers;
  final Duration heartbeatInterval;
  final int staleSeconds;
  final PeriodicTimerFactory _timerFactory;

  final StreamController<PresenceNotice> _notices =
      StreamController<PresenceNotice>.broadcast();

  Timer? _heartbeatTimer;
  bool _started = false;
  bool _isOnlineMode = false;
  bool _running = false;
  bool _disposed = false;

  Map<String, Player> _previousOnline = {};
  String? _previousHostId;
  String? _lastAnnouncedHostId;
  final Set<String> _announcedOffline = <String>{};

  PresenceCoordinator({
    required this.roomId,
    required this.currentUserId,
    required this.setPresence,
    required this.cleanupStalePlayers,
    this.heartbeatInterval = defaultHeartbeatInterval,
    this.staleSeconds = defaultStaleSeconds,
    PeriodicTimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? _defaultTimerFactory;

  Stream<PresenceNotice> get notices => _notices.stream;

  bool get isRunning => _running;

  /// Begins presence (widget mounted/activated). Idempotent.
  void start() {
    if (_disposed || _started) return;
    _started = true;
    _syncRunning();
  }

  /// Pauses presence (widget deactivated). Keeps the snapshot baseline.
  void stop() {
    if (_disposed || !_started) return;
    _started = false;
    _syncRunning();
  }

  /// Presence only runs for online games; pass the room's game mode.
  void setGameMode(String gameMode) {
    if (_disposed) return;
    _isOnlineMode = gameMode == GameConstants.gameModeOnline;
    _syncRunning();
  }

  void onResumed() {
    if (!_running) return;
    _sendPresence(true);
    _startHeartbeat();
    _cleanup();
  }

  void onBackgrounded() {
    if (!_running) return;
    _stopHeartbeat();
    _sendPresence(false);
  }

  /// Feeds the latest player list. With [notify] false the list only becomes
  /// the new baseline (first snapshot, re-activation).
  void onPlayersUpdated(List<Player> players, {bool notify = true}) {
    if (_disposed) return;

    final online = <String, Player>{
      for (final p in players)
        if (p.isOnline) p.id: p,
    };

    Player? currentHost;
    for (final p in online.values) {
      if (p.isHost) {
        currentHost = p;
        break;
      }
    }
    final currentHostId = currentHost?.id;

    _announcedOffline.removeWhere(online.containsKey);

    if (notify && _previousOnline.isNotEmpty) {
      final me = currentUserId();
      final newlyDisconnected = _previousOnline.values
          .where((prev) => prev.userId != me && !online.containsKey(prev.id))
          .where((prev) => _announcedOffline.add(prev.id))
          .map((p) => DepartedPlayer(id: p.id, username: p.username))
          .toList(growable: false);

      if (newlyDisconnected.isNotEmpty) {
        _emit(PlayersLeftNotice(newlyDisconnected));
      }

      if (_previousHostId != null &&
          currentHost != null &&
          _previousHostId != currentHostId &&
          _lastAnnouncedHostId != currentHostId) {
        _lastAnnouncedHostId = currentHostId;
        _emit(
          NewHostNotice(
            playerId: currentHost.id,
            username: currentHost.username,
          ),
        );
      }
    }

    _previousOnline = online;
    _previousHostId = currentHostId;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _started = false;
    _running = false;
    _stopHeartbeat();
    unawaited(_notices.close());
  }

  void _syncRunning() {
    final shouldRun = _started && _isOnlineMode && !_disposed;
    if (shouldRun == _running) return;
    _running = shouldRun;
    if (shouldRun) {
      _sendPresence(true);
      _startHeartbeat();
      _cleanup();
    } else {
      _stopHeartbeat();
    }
  }

  void _emit(PresenceNotice notice) {
    if (!_notices.isClosed && _notices.hasListener) _notices.add(notice);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = _timerFactory(heartbeatInterval, () {
      if (!_running) return;
      _sendPresence(true);
      _cleanup();
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _sendPresence(bool isOnline) {
    final userId = currentUserId();
    if (userId == null) return;
    unawaited(
      _guard(
        () => setPresence(roomId: roomId, userId: userId, isOnline: isOnline),
      ),
    );
  }

  /// Best-effort stale cleanup; failures are never surfaced.
  void _cleanup() {
    unawaited(
      _guard(
        () => cleanupStalePlayers(roomId: roomId, staleSeconds: staleSeconds),
      ),
    );
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Best-effort; the next heartbeat retries.
    }
  }
}

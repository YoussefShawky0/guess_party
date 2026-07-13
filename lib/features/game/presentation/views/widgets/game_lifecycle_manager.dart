import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class GameLifecycleManager extends StatefulWidget {
  final String roomId;
  final Widget child;

  const GameLifecycleManager({
    super.key,
    required this.roomId,
    required this.child,
  });

  @override
  State<GameLifecycleManager> createState() => _GameLifecycleManagerState();
}

class _GameLifecycleManagerState extends State<GameLifecycleManager>
    with WidgetsBindingObserver {
  static const _heartbeatInterval = Duration(seconds: 25);
  Timer? _heartbeatTimer;
  StreamSubscription<GameState>? _gameStateSubscription;
  Map<String, Map<String, dynamic>> _previousOnlinePlayers = {};
  String? _previousHostPlayerId;
  String? _lastAnnouncedHostPlayerId;
  String? _lastPresenceBannerKey;
  DateTime? _lastPresenceBannerAt;
  final Set<String> _announcedOfflinePlayerIds = <String>{};
  bool _isRefreshingPresenceSnapshot = false;

  late final GameCubit _gameCubit;
  bool _isActive = true;
  bool _isObserving = false;
  bool _isResumeRefreshInFlight = false;

  Future<void> _setCurrentUserOnlineStatus(bool isOnline) async {
    final userId = sl<AuthSessionService>().currentUserId;
    if (userId == null) return;

    try {
      await _gameCubit.setCurrentPlayerPresence(
        roomId: widget.roomId,
        userId: userId,
        isOnline: isOnline,
      );
    } catch (_) {
      // Best-effort heartbeat/status update.
    }
  }

  Future<void> _cleanupStalePlayers() async {
    await sl<MarkStalePlayersOffline>()(
      roomId: widget.roomId,
      staleSeconds: 90,
    );
  }

  /// Returns true if the authenticated user is currently the room host.
  /// Used to restrict stale-player cleanup to the host only (Step 7).
  bool _isCurrentUserHost() {
    final cubitState = _gameCubit.state;
    if (cubitState is! GameLoaded) return false;
    final currentUserId = sl<AuthSessionService>().currentUserId;
    if (currentUserId == null) return false;
    for (final player in cubitState.gameState.players) {
      if (player.userId == currentUserId) {
        return player.isHost;
      }
    }
    return false;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _setCurrentUserOnlineStatus(true);
      // Step 7: Only the host runs stale-player cleanup. Avoids N players
      // all calling the same RPC every 25 seconds (~14x/min with 6 players).
      if (_isCurrentUserHost()) {
        unawaited(_cleanupStalePlayers());
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelPresenceRetry() {
    // Retry/backoff is owned by the repository stream adapter.
  }

  void _unsubscribeFromPlayersRealtime() {
    _cancelPresenceRetry();

    _gameStateSubscription?.cancel();
    _gameStateSubscription = null;
  }

  void _showPresenceBanner(String message, {Color? color, String? dedupeKey}) {
    if (!mounted) return;
    final key = dedupeKey ?? message;
    final now = DateTime.now();
    if (_lastPresenceBannerKey == key &&
        _lastPresenceBannerAt != null &&
        now.difference(_lastPresenceBannerAt!) < const Duration(seconds: 4)) {
      return;
    }

    _lastPresenceBannerKey = key;
    _lastPresenceBannerAt = now;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _refreshPresenceSnapshot({bool notify = true}) async {
    if (_isRefreshingPresenceSnapshot) return;
    _isRefreshingPresenceSnapshot = true;

    try {
      final currentUserId = sl<AuthSessionService>().currentUserId;
      if (!mounted) return;

      final onlinePlayers = <String, Map<String, dynamic>>{};
      final cubitState = _gameCubit.state;
      if (cubitState is GameLoaded) {
        for (final player in cubitState.gameState.players) {
          if (player.isOnline) {
            onlinePlayers[player.id] = <String, dynamic>{
              'id': player.id,
              'user_id': player.userId,
              'username': player.username,
              'is_host': player.isHost,
              'is_online': player.isOnline,
              'created_at': player.createdAt?.toIso8601String(),
            };
          }
        }
      }

      final currentHost = onlinePlayers.values.where(
        (player) => player['is_host'] as bool? ?? false,
      );
      final currentHostPlayerId = currentHost.isEmpty
          ? null
          : currentHost.first['id'] as String;

      _announcedOfflinePlayerIds.removeWhere(onlinePlayers.containsKey);

      if (notify && _previousOnlinePlayers.isNotEmpty) {
        final disconnected = _previousOnlinePlayers.values.where((previous) {
          final previousId = previous['id'] as String?;
          final previousUserId = previous['user_id'] as String?;
          if (previousId == null) return false;
          if (previousUserId == currentUserId) return false;
          return !onlinePlayers.containsKey(previousId);
        }).toList();

        final newlyDisconnected = disconnected.where((player) {
          final playerId = player['id'] as String?;
          if (playerId == null) return false;
          return _announcedOfflinePlayerIds.add(playerId);
        }).toList();

        if (newlyDisconnected.isNotEmpty) {
          final names = newlyDisconnected
              .map((player) => player['username']?.toString() ?? 'Player')
              .toList();
          final label = names.length == 1
              ? '${names.first} has left the game'
              : '${names.join(', ')} have left the game';
          final offlineIds = newlyDisconnected
            ..sort((a, b) {
              final aId = a['id']?.toString() ?? '';
              final bId = b['id']?.toString() ?? '';
              return aId.compareTo(bId);
            });
          final dedupeIds = offlineIds
              .map((player) => player['id']?.toString() ?? '')
              .where((id) => id.isNotEmpty)
              .join('|');
          _showPresenceBanner(label, dedupeKey: 'left:$dedupeIds');
        }

        if (_previousHostPlayerId != null &&
            currentHostPlayerId != null &&
            _previousHostPlayerId != currentHostPlayerId &&
            _lastAnnouncedHostPlayerId != currentHostPlayerId) {
          final hostName = currentHost.isEmpty
              ? 'A player'
              : currentHost.first['username']?.toString() ?? 'A player';
          _lastAnnouncedHostPlayerId = currentHostPlayerId;
          _showPresenceBanner(
            '$hostName is now the host',
            color: AppColors.success,
            dedupeKey: 'host:$currentHostPlayerId',
          );
        }
      }

      _previousOnlinePlayers = onlinePlayers;
      _previousHostPlayerId = currentHostPlayerId;
    } catch (_) {
      // Presence updates are best-effort to avoid disrupting gameplay.
    } finally {
      _isRefreshingPresenceSnapshot = false;
    }
  }

  void _subscribeToPresenceChanges() {
    if (!_isActive || !mounted) return;

    _unsubscribeFromPlayersRealtime();
    _gameStateSubscription = _gameCubit.stream.listen((state) {
      if (!mounted || !_isActive) return;
      if (state is GameLoaded) {
        unawaited(_refreshPresenceSnapshot());
      }
    });
  }

  // ── Step 10: Room-status watcher ───────────────────────────────────────────
  // Watches `rooms.status`. When the DB function reconcile_room_after_presence_change
  // sets status='finished' (all players disconnected), navigates the client
  // to game-over or home rather than leaving them on a stale game screen.

  void _subscribeToRoomStatus() {
    // Room status is part of GameCubit's repository-owned session stream.
  }

  void _unsubscribeFromRoomStatus() {
    // Room status is cancelled with GameCubit.
  }

  @override
  void initState() {
    super.initState();

    // Cache cubit reference to avoid ancestor lookup during lifecycle callbacks.
    _gameCubit = context.read<GameCubit>();

    WidgetsBinding.instance.addObserver(this);
    _isObserving = true;
    _setCurrentUserOnlineStatus(true);
    _startHeartbeat();
    _refreshPresenceSnapshot(notify: false);
    // Run cleanup once on init regardless of host (catch-up); periodic is host-only.
    unawaited(_cleanupStalePlayers());
    _subscribeToPresenceChanges();
    _subscribeToRoomStatus(); // Step 10
  }

  @override
  void deactivate() {
    _isActive = false;
    _stopHeartbeat();
    _unsubscribeFromPlayersRealtime();
    _unsubscribeFromRoomStatus(); // Step 10

    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }

    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActive = true;

    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    }

    _setCurrentUserOnlineStatus(true);
    _startHeartbeat();
    _refreshPresenceSnapshot(notify: false);
    if (_isCurrentUserHost()) {
      unawaited(_cleanupStalePlayers());
    }
    _subscribeToPresenceChanges();
    _subscribeToRoomStatus(); // Step 10
  }

  @override
  void dispose() {
    _isActive = false;
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
    _stopHeartbeat();
    _unsubscribeFromPlayersRealtime();
    _unsubscribeFromRoomStatus(); // Step 10
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_isActive || _gameCubit.isClosed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setCurrentUserOnlineStatus(true);
        _startHeartbeat();
        if (_isCurrentUserHost()) {
          unawaited(_cleanupStalePlayers()); // host-only on resume
        }

        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'lifecycle',
            message: 'game resumed: refreshing state',
            level: SentryLevel.info,
            data: {'roomId': widget.roomId},
          ),
        );

        unawaited(_refreshGameStateOnResume());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _setCurrentUserOnlineStatus(false);
        break;
    }
  }

  Future<void> _refreshGameStateOnResume() async {
    if (_isResumeRefreshInFlight || _gameCubit.isClosed) return;
    _isResumeRefreshInFlight = true;
    try {
      await _gameCubit.refreshGameStateOnResume(roomId: widget.roomId);
    } finally {
      _isResumeRefreshInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

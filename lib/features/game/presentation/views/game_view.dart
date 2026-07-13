import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:guess_party/shared/widgets/chat_widget.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/character_card.dart';
import 'widgets/results_phase_content.dart';
import 'widgets/round_header_widget.dart';
import 'widgets/voting_phase_content.dart';

class GameView extends StatelessWidget {
  final String roomId;
  final Map<String, int>? preservedScores;

  const GameView({super.key, required this.roomId, this.preservedScores});

  @override
  Widget build(BuildContext context) {
    final session = sl<AuthSessionService>();
    return StreamBuilder<String?>(
      stream: session.userIdChanges,
      initialData: session.currentUserId,
      builder: (context, snapshot) {
        final currentUserId = snapshot.data;
        if (currentUserId == null) {
          return Scaffold(
            backgroundColor: AppColors.of(context).background,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (context) => sl<GameCubit>()
            ..loadGameState(
              roomId: roomId,
              currentPlayerId: currentUserId,
              preservedScores: preservedScores,
            ),
          child: GameLifecycleManager(
            roomId: roomId,
            child: GameViewContent(roomId: roomId),
          ),
        );
      },
    );
  }
}

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
  Timer? _presenceRetryTimer;
  RealtimeChannel? _playersChannel;
  RealtimeChannel? _roomStatusChannel;
  Map<String, Map<String, dynamic>> _previousOnlinePlayers = {};
  String? _previousHostPlayerId;
  String? _lastAnnouncedHostPlayerId;
  String? _lastPresenceBannerKey;
  DateTime? _lastPresenceBannerAt;
  final Set<String> _announcedOfflinePlayerIds = <String>{};
  bool _isRefreshingPresenceSnapshot = false;
  int _presenceSubscriptionGeneration = 0;

  late final GameCubit _gameCubit;
  bool _isActive = true;
  bool _isObserving = false;
  bool _isResumeRefreshInFlight = false;

  Future<void> _setCurrentUserOnlineStatus(bool isOnline) async {
    final userId = sl<AuthSessionService>().currentUserId;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('players')
          .update({
            'is_online': isOnline,
            'last_seen_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('room_id', widget.roomId)
          .eq('user_id', userId);
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
    _presenceRetryTimer?.cancel();
    _presenceRetryTimer = null;
  }

  void _schedulePresenceRetry({required int generation}) {
    if (!mounted || !_isActive) return;

    _cancelPresenceRetry();
    _presenceRetryTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isActive) return;
      if (generation != _presenceSubscriptionGeneration) return;
      _subscribeToPresenceChanges();
    });
  }

  void _unsubscribeFromPlayersRealtime() {
    _cancelPresenceRetry();
    _presenceSubscriptionGeneration++;

    final channel = _playersChannel;
    _playersChannel = null;
    if (channel != null) {
      channel.unsubscribe();
      Supabase.instance.client.removeChannel(channel);
    }
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
      final response = await Supabase.instance.client
          .from('players')
          .select('id, user_id, username, is_host, is_online, created_at')
          .eq('room_id', widget.roomId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      final onlinePlayers = <String, Map<String, dynamic>>{};
      for (final row in (response as List).cast<Map<String, dynamic>>()) {
        if ((row['is_online'] as bool? ?? true) == true) {
          onlinePlayers[row['id'] as String] = row;
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
    final generation = _presenceSubscriptionGeneration;

    try {
      final channel = Supabase.instance.client
          .channel('game_players_${widget.roomId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'players',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: widget.roomId,
            ),
            callback: (_) {
              _refreshPresenceSnapshot();
            },
          );

      channel.subscribe((status, error) {
        if (generation != _presenceSubscriptionGeneration) return;
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.closed) {
          _schedulePresenceRetry(generation: generation);
        }
      });

      _playersChannel = channel;
    } catch (_) {
      if (generation == _presenceSubscriptionGeneration) {
        _schedulePresenceRetry(generation: generation);
      }
    }
  }

  // ── Step 10: Room-status watcher ───────────────────────────────────────────
  // Watches `rooms.status`. When the DB function reconcile_room_after_presence_change
  // sets status='finished' (all players disconnected), navigates the client
  // to game-over or home rather than leaving them on a stale game screen.

  void _subscribeToRoomStatus() {
    _unsubscribeFromRoomStatus();

    _roomStatusChannel = Supabase.instance.client
        .channel('room_status_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.roomId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final status = newRecord['status'] as String?;
            if (status == 'finished' && mounted && _isActive) {
              _handleRoomFinished();
            }
          },
        );

    _roomStatusChannel!.subscribe();
  }

  void _handleRoomFinished() {
    if (!mounted) return;
    final cubitState = _gameCubit.state;
    if (cubitState is GameLoaded) {
      final ctx = context;
      if (ctx.mounted) {
        ctx.go(
          AppRoutes.roomGameOver(widget.roomId),
          extra: {
            'players': cubitState.gameState.players,
            'playerScores': cubitState.gameState.playerScores,
          },
        );
      }
    } else {
      if (context.mounted) {
        context.go(AppRoutes.home);
      }
    }
  }

  void _unsubscribeFromRoomStatus() {
    final channel = _roomStatusChannel;
    _roomStatusChannel = null;
    if (channel != null) {
      channel.unsubscribe();
      Supabase.instance.client.removeChannel(channel);
    }
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

class GameViewContent extends StatefulWidget {
  final String roomId;

  const GameViewContent({super.key, required this.roomId});

  @override
  State<GameViewContent> createState() => _GameViewContentState();
}

class _GameViewContentState extends State<GameViewContent> {
  static const _backOnlineCooldown = Duration(seconds: 6);
  static const _minReconnectCycleForBackOnline = Duration(seconds: 1);
  bool _isReconnectCycleActive = false;
  bool _backOnlineShownForCycle = false;
  DateTime? _reconnectCycleStartedAt;
  DateTime? _lastBackOnlineAt;
  String?
  _isAdvancingHintsRoundId; // Step 8: guard hints→voting duplicate transitions
  String?
  _isFinalizingVotingRoundId; // Track which round is currently finalizing

  Player? _resolveCurrentRoomPlayer(GameStateEntity gameState) {
    final currentPlayerIdentifier = gameState.currentPlayerId;
    if (currentPlayerIdentifier.isEmpty) {
      return null;
    }

    for (final player in gameState.players) {
      if (player.id == currentPlayerIdentifier ||
          player.userId == currentPlayerIdentifier) {
        return player;
      }
    }

    return null;
  }

  bool _isCurrentRoomHost(GameStateEntity gameState) =>
      _resolveCurrentRoomPlayer(gameState)?.isHost ?? false;

  bool _shouldAutoFinalizeVoting(GameLoaded previous, GameLoaded current) {
    final prevRound = previous.gameState.currentRound;
    final currRound = current.gameState.currentRound;
    final currGameState = current.gameState;

    // Only for online mode
    if (currGameState.gameMode != GameConstants.gameModeOnline) {
      return false;
    }

    // Only if current phase is voting
    if (currRound.phase != GamePhase.voting) {
      return false;
    }

    // Only if current player is host
    if (!_isCurrentRoomHost(currGameState)) {
      return false;
    }

    // Only if not currently finalizing (manual button or timer race guard)
    if (_isFinalizingVotingRoundId == currRound.id) {
      return false;
    }

    final previousComplete = prevRound.allRequiredVotesSubmitted;
    final currentComplete = currRound.allRequiredVotesSubmitted;
    final onlinePlayerCount = current.gameState.players
        .where((p) => p.isOnline)
        .length;

    // Safety: need at least 2 online players for meaningful voting
    if (onlinePlayerCount < 2) return false;

    final votesJustCompleted = !previousComplete && currentComplete;

    if (!votesJustCompleted) {
      return false;
    }

    // All conditions met
    return true;
  }

  void _finalizeVotingAndProgress(
    BuildContext context,
    String roundId, {
    String reason = 'all_votes',
  }) {
    if (_isFinalizingVotingRoundId == roundId) {
      return;
    }

    _isFinalizingVotingRoundId = roundId;
    context.read<GameCubit>().finalizeVoting(roundId, reason).whenComplete(() {
      if (mounted) _isFinalizingVotingRoundId = null;
    });
  }

  Future<bool> _showLeaveConfirmation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.of(context).surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Leave Game?',
                  style: TextStyle(color: AppColors.of(context).textPrimary),
                ),
              ],
            ),
            content: Text(
              'Are you sure you want to leave? This will affect the current game.',
              style: TextStyle(
                color: AppColors.of(context).textSecondary,
                fontSize: 16,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Stay',
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.of(context).textPrimary,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleLeaveGame(BuildContext context) async {
    final gameCubit = context.read<GameCubit>();
    final currentGameState = gameCubit.state;
    final isActivePhase =
        currentGameState is GameLoaded &&
        (currentGameState.gameState.currentRound.phase == GamePhase.hints ||
            currentGameState.gameState.currentRound.phase == GamePhase.voting);

    if (isActivePhase) {
      final shouldLeave = await _showLeaveConfirmation(context);
      if (!shouldLeave || !context.mounted) return;
    }

    // Get player info from game state
    final gameState = currentGameState;
    if (gameState is GameLoaded) {
      final currentPlayer = _resolveCurrentRoomPlayer(gameState.gameState);
      if (currentPlayer == null) {
        if (context.mounted) {
          ErrorSnackBar.show(context, 'Syncing your player. Try again.');
        }
        return;
      }

      await sl<LeaveRoom>()(
        playerId: currentPlayer.id,
        roomId: widget.roomId,
        isHost: currentPlayer.isHost,
      );
    }

    if (context.mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleLeaveGame(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.of(context).background,
        appBar: AppBar(
          title: const Text('Game'),
          backgroundColor: AppColors.of(context).surface,
          foregroundColor: AppColors.of(context).textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleLeaveGame(context),
          ),
        ),
        body: BlocConsumer<GameCubit, GameState>(
          listenWhen: (previous, current) {
            if (previous is GameLoaded && current is GameLoaded) {
              final hasNewInlineMessage =
                  current.nonFatalMessage != null &&
                  current.nonFatalMessageId != previous.nonFatalMessageId;
              if (hasNewInlineMessage) return true;

              final reconnectStarted =
                  !previous.isReconnecting && current.isReconnecting;
              if (reconnectStarted) {
                _isReconnectCycleActive = true;
                _backOnlineShownForCycle = false;
                _reconnectCycleStartedAt = DateTime.now();
                return false;
              }

              final reconnectEnded =
                  previous.isReconnecting && !current.isReconnecting;
              if (reconnectEnded) return true;

              // Check for auto-finalize voting condition
              final shouldAutoFinalizeVoting = _shouldAutoFinalizeVoting(
                previous,
                current,
              );
              if (shouldAutoFinalizeVoting) return true;

              return false;
            }
            return current is GameError ||
                current is GameEnded ||
                (current is GameLoaded && current.nonFatalMessage != null);
          },
          listener: (context, state) {
            // Auto-finalize voting: trigger score calculation and phase advance
            if (state is GameLoaded &&
                state.gameState.currentRound.phase == GamePhase.voting &&
                state.gameState.currentRound.allRequiredVotesSubmitted &&
                _isCurrentRoomHost(state.gameState) &&
                _isFinalizingVotingRoundId == null) {
              final round = state.gameState.currentRound;
              _isFinalizingVotingRoundId = round.id;
              context
                  .read<GameCubit>()
                  .finalizeVoting(round.id, 'all_votes')
                  .whenComplete(() {
                    if (mounted) _isFinalizingVotingRoundId = null;
                  });
            }

            // Show error messages with better styling
            if (state is GameError) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.of(context).textPrimary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.message,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is GameLoaded && state.nonFatalMessage != null) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.of(context).textPrimary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          state.nonFatalMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is GameLoaded && !state.isReconnecting) {
              if (!context.mounted) return;
              final now = DateTime.now();
              final reconnectDuration = _reconnectCycleStartedAt == null
                  ? Duration.zero
                  : now.difference(_reconnectCycleStartedAt!);
              final isWithinCooldown =
                  _lastBackOnlineAt != null &&
                  now.difference(_lastBackOnlineAt!) < _backOnlineCooldown;

              if (!_isReconnectCycleActive ||
                  _backOnlineShownForCycle ||
                  reconnectDuration < _minReconnectCycleForBackOnline ||
                  isWithinCooldown) {
                _isReconnectCycleActive = false;
                return;
              }

              _isReconnectCycleActive = false;
              _backOnlineShownForCycle = true;
              _lastBackOnlineAt = now;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.wifi,
                        color: AppColors.of(context).textPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Back online. Game synced.',
                          style: TextStyle(
                            color: AppColors.of(context).textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.success,
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is GameEnded) {
              if (!context.mounted) return;
              context.go(
                AppRoutes.roomGameOver(widget.roomId),
                extra: {
                  'players': state.players,
                  'playerScores': state.playerScores,
                },
              );
            }
          },
          builder: (context, state) {
            if (state is GameLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Loading game...',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is GameError) {
              return ErrorScreen(
                message: state.message,
                onRetry: () {
                  context.read<GameCubit>().loadGameState(
                    roomId: widget.roomId,
                    currentPlayerId: context.read<GameCubit>().currentPlayerId,
                  );
                },
                onGoBack: () => context.go(AppRoutes.home),
              );
            }

            if (state is GameLoaded) {
              return Stack(
                children: [
                  _buildGameContent(context, state),
                  if (state.isReconnecting)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.of(context).textPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Reconnecting to game...',
                                style: TextStyle(
                                  color: AppColors.of(context).textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }

            return const Center(child: Text('Preparing...'));
          },
        ),
      ),
    );
  }

  Widget _buildGameContent(BuildContext context, GameLoaded state) {
    final gameState = state.gameState;
    final round = gameState.currentRound;
    final currentPlayerIdentifier = gameState.currentPlayerId;
    final players = gameState.players;

    if (players.isEmpty) {
      return Center(
        child: Text(
          'Waiting for players...',
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
      );
    }

    final isTablet = MediaQuery.of(context).size.width > 600;
    final currentPlayer = _resolveCurrentRoomPlayer(gameState);
    final currentRoomPlayerId = currentPlayer?.id;
    final isCurrentPlayerUnresolved =
        gameState.gameMode == GameConstants.gameModeOnline &&
        (currentRoomPlayerId == null || currentRoomPlayerId.isEmpty);
    // SECURITY FIX: When player identity is unresolved, default to NOT
    // imposter and show a syncing indicator. The old code defaulted to
    // showing the imposter card, leaking information (only innocents
    // experience a desync, not the real imposter).
    final isImposter =
        !isCurrentPlayerUnresolved &&
        currentRoomPlayerId != null &&
        round.isImposter(currentRoomPlayerId);
    final isHost = currentPlayer?.isHost == true;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RoundHeaderWidget(
            round: round,
            totalRounds: gameState.totalRounds,
            roundDuration: gameState.roundDuration,
            onTimeUp: () => _handlePhaseTimeUp(context, state),
          ),
          const SizedBox(height: 16),

          // Character Card Widget — show syncing card if player identity
          // cannot yet be resolved (e.g. immediately after reconnection).
          if (isCurrentPlayerUnresolved)
            Container(
              decoration: BoxDecoration(
                color: AppColors.of(context).cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.of(context).cardBorder,
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Syncing your role...',
                    style: TextStyle(
                      color: AppColors.of(context).textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          else
            CharacterCard(
              character: round.character,
              isImposter: isImposter,
              gameMode: state.gameState.gameMode,
            ),
          const SizedBox(height: 16),
          if (gameState.gameMode == GameConstants.gameModeOnline &&
              (round.phase == GamePhase.hints ||
                  round.phase == GamePhase.voting) &&
              isHost) ...[
            ElevatedButton.icon(
              onPressed: () async {
                final isHintsPhase = round.phase == GamePhase.hints;
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(isHintsPhase ? 'Skip hints?' : 'Skip voting?'),
                    content: Text(
                      isHintsPhase
                          ? 'Are you sure you want to skip to voting?'
                          : 'Are you sure you want to skip to results?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  if (isHintsPhase) {
                    // Step 8: guard hints→voting duplicate transition
                    if (_isAdvancingHintsRoundId == round.id) return;
                    _isAdvancingHintsRoundId = round.id;
                    context
                        .read<GameCubit>()
                        .progressPhase(round.id)
                        .then((_) {
                          if (mounted) _isAdvancingHintsRoundId = null;
                        })
                        .catchError((_) {
                          if (mounted) _isAdvancingHintsRoundId = null;
                        });
                  } else {
                    _finalizeVotingAndProgress(
                      context,
                      round.id,
                      reason: 'host_skip',
                    );
                  }
                }
              },
              icon: const Icon(Icons.skip_next),
              label: Text(
                round.phase == GamePhase.hints
                    ? 'Skip to Voting'
                    : 'Skip to Results',
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Phase-specific content
          if (round.phase == GamePhase.hints)
            ChatWidget(
              roomId: widget.roomId,
              roundId: round.id,
              currentPlayerId: currentPlayer?.id ?? currentPlayerIdentifier,
            ),
          if (round.phase == GamePhase.voting)
            VotingPhaseContent(
              round: round,
              players: state.gameState.players,
              gameMode: state.gameState.gameMode,
              currentUserId: currentPlayerIdentifier,
              isHost: isHost,
              isFinalizingVoting: _isFinalizingVotingRoundId == round.id,
              onShowResults: () {
                _finalizeVotingAndProgress(context, round.id);
              },
            ),
          if (round.phase == GamePhase.results)
            _buildResultsPhase(context, state),
        ],
      ),
    );
  }

  void _startNextRound(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final nextRoundNumber = round.roundNumber + 1;

    context.read<GameCubit>().createNewRound(
      roomId: widget.roomId,
      roundNumber: nextRoundNumber,
    );
  }

  Widget _buildResultsPhase(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final players = state.gameState.players;
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }
    final isLastRound = state.gameState.isLastRound;

    // Count votes
    final voteCounts = round.voteCounts;

    final isHost = _isCurrentRoomHost(state.gameState);

    return ResultsPhaseContent(
      roundInfo: round,
      players: players,
      playerScores: state.gameState.playerScores,
      voteCounts: voteCounts,
      onNextRound: () => _startNextRound(context, state),
      onGameEnd: () {
        context.read<GameCubit>().finishGame(widget.roomId);
      },
      isHost: isHost,
      isLastRound: isLastRound,
      totalRounds: state.gameState.totalRounds,
    );
  }

  void _handlePhaseTimeUp(BuildContext context, GameLoaded state) {
    final round = state.gameState.currentRound;
    final isHost = _isCurrentRoomHost(state.gameState);

    // Only host can advance phase
    if (!isHost) {
      return;
    }

    final phase = round.phase;

    if (phase == GamePhase.hints) {
      // Step 8: Guard duplicate hints→voting transition (mirrors voting guard)
      if (_isAdvancingHintsRoundId == round.id) {
        return;
      }
      _isAdvancingHintsRoundId = round.id;
      context
          .read<GameCubit>()
          .progressPhase(round.id)
          .then((_) {
            if (mounted) _isAdvancingHintsRoundId = null;
          })
          .catchError((_) {
            if (mounted) _isAdvancingHintsRoundId = null;
          });
    } else if (phase == GamePhase.voting) {
      // Guard: do not fire timer if voting is already being finalized
      // (by auto-transition or manual button)
      if (_isFinalizingVotingRoundId == round.id) {
        return;
      }

      _isFinalizingVotingRoundId = round.id;
      context.read<GameCubit>().finalizeVoting(round.id, 'timer').whenComplete(
        () {
          if (mounted) _isFinalizingVotingRoundId = null;
        },
      );
    }
    // Results phase is button-driven only — no auto-advance
  }
}

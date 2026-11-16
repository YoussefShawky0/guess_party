import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/cubit/presence_coordinator.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Thin adapter between the widget lifecycle / [GameCubit] and the
/// plain-Dart [PresenceCoordinator]: forwards lifecycle and player updates in,
/// shows localized banners for the typed notices coming out.
class GameLifecycleManager extends StatefulWidget {
  final String roomId;
  final AuthSessionService session;
  final RoomRepository roomRepository;
  final Widget child;

  const GameLifecycleManager({
    super.key,
    required this.roomId,
    required this.session,
    required this.roomRepository,
    required this.child,
  });

  @override
  State<GameLifecycleManager> createState() => _GameLifecycleManagerState();
}

class _GameLifecycleManagerState extends State<GameLifecycleManager>
    with WidgetsBindingObserver {
  late final GameCubit _gameCubit;
  late final PresenceCoordinator _presence;
  StreamSubscription<GameState>? _gameStateSubscription;
  StreamSubscription<PresenceNotice>? _noticeSubscription;

  String? _lastBannerKey;
  DateTime? _lastBannerAt;

  bool _isActive = true;
  bool _isObserving = false;
  bool _isResumeRefreshInFlight = false;

  @override
  void initState() {
    super.initState();

    // Cache cubit reference to avoid ancestor lookup during lifecycle callbacks.
    _gameCubit = context.read<GameCubit>();
    _presence = PresenceCoordinator(
      roomId: widget.roomId,
      currentUserId: () => widget.session.currentUserId,
      setPresence: _gameCubit.setCurrentPlayerPresence,
      cleanupStalePlayers: ({required roomId, required staleSeconds}) async {
        await widget.roomRepository.markStalePlayersOffline(
          roomId: roomId,
          staleSeconds: staleSeconds,
        );
      },
    );
    _noticeSubscription = _presence.notices.listen(_showNotice);

    WidgetsBinding.instance.addObserver(this);
    _isObserving = true;
    _activate();
  }

  void _activate() {
    _isActive = true;
    _syncFromCubit(_gameCubit.state, notify: false);
    _presence.start();
    _gameStateSubscription?.cancel();
    _gameStateSubscription = _gameCubit.stream.listen((state) {
      if (!mounted || !_isActive) return;
      _syncFromCubit(state);
    });
  }

  void _syncFromCubit(GameState state, {bool notify = true}) {
    if (state is! GameLoaded) return;
    _presence.setGameMode(state.gameState.gameMode);
    _presence.onPlayersUpdated(state.gameState.players, notify: notify);
  }

  void _showNotice(PresenceNotice notice) {
    if (!mounted) return;
    final l10n = context.l10n;
    switch (notice) {
      case PlayersLeftNotice(:final players):
        final names = players.map((p) => p.username).toList();
        _showBanner(
          names.length == 1
              ? l10n.playerLeftGame(names.first)
              : l10n.playersLeftGame(names.join(', ')),
          dedupeKey: notice.dedupeKey,
        );
      case NewHostNotice(:final username):
        _showBanner(
          l10n.playerIsNowHost(username),
          color: AppColors.success,
          dedupeKey: notice.dedupeKey,
        );
    }
  }

  void _showBanner(String message, {Color? color, required String dedupeKey}) {
    if (!mounted) return;
    final now = DateTime.now();
    if (_lastBannerKey == dedupeKey &&
        _lastBannerAt != null &&
        now.difference(_lastBannerAt!) < const Duration(seconds: 4)) {
      return;
    }
    _lastBannerKey = dedupeKey;
    _lastBannerAt = now;

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

  @override
  void deactivate() {
    _isActive = false;
    _presence.stop();
    _gameStateSubscription?.cancel();
    _gameStateSubscription = null;

    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }

    super.deactivate();
  }

  @override
  void activate() {
    super.activate();

    if (!_isObserving) {
      WidgetsBinding.instance.addObserver(this);
      _isObserving = true;
    }
    _activate();
  }

  @override
  void dispose() {
    _isActive = false;
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
    _gameStateSubscription?.cancel();
    _gameStateSubscription = null;
    _noticeSubscription?.cancel();
    _noticeSubscription = null;
    _presence.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || !_isActive || _gameCubit.isClosed) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _presence.onResumed();

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
        _presence.onBackgrounded();
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

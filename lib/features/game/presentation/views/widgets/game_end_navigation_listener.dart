import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

class GameEndNavigationListener extends StatefulWidget {
  final String roomId;
  final Stream<GameState> states;
  final Widget child;

  const GameEndNavigationListener({
    super.key,
    required this.roomId,
    required this.states,
    required this.child,
  });

  @override
  State<GameEndNavigationListener> createState() =>
      _GameEndNavigationListenerState();
}

class _GameEndNavigationListenerState extends State<GameEndNavigationListener> {
  StreamSubscription<GameState>? _subscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant GameEndNavigationListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.states != widget.states ||
        oldWidget.roomId != widget.roomId) {
      _subscription?.cancel();
      _hasNavigated = false;
      _subscribe();
    }
  }

  void _subscribe() {
    _subscription = widget.states.listen((state) {
      if (!mounted || _hasNavigated || state is! GameEnded) return;
      _hasNavigated = true;
      context.go(
        AppRoutes.roomGameOver(widget.roomId),
        extra: {'players': state.players, 'playerScores': state.playerScores},
      );
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

class RoomLifecycleManager extends StatefulWidget {
  final String roomId;
  final Widget child;
  final Function(String playerId, bool isHost) onPlayerIdentified;

  const RoomLifecycleManager({
    super.key,
    required this.roomId,
    required this.child,
    required this.onPlayerIdentified,
  });

  @override
  State<RoomLifecycleManager> createState() => _RoomLifecycleManagerState();
}

class _RoomLifecycleManagerState extends State<RoomLifecycleManager>
    with WidgetsBindingObserver {
  String? _currentPlayerId;
  bool? _isHost;
  RoomCubit? _roomCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _roomCubit ??= context.read<RoomCubit>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Leave room when disposing
    if (_currentPlayerId != null && _isHost != null && _roomCubit != null) {
      _roomCubit!.leaveRoomSession(
        playerId: _currentPlayerId!,
        roomId: widget.roomId,
        isHost: _isHost!,
      );
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentPlayerId == null || _roomCubit == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _roomCubit!.setPlayerStatus(
          playerId: _currentPlayerId!,
          isOnline: true,
        );
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _roomCubit!.setPlayerStatus(
          playerId: _currentPlayerId!,
          isOnline: false,
        );
        break;
    }
  }

  void updatePlayerInfo(String playerId, bool isHost) {
    if (_currentPlayerId == null) {
      setState(() {
        _currentPlayerId = playerId;
        _isHost = isHost;
      });
      widget.onPlayerIdentified(playerId, isHost);
    }
  }

  Future<void> handleBackNavigation() async {
    if (_currentPlayerId != null && _isHost != null && _roomCubit != null) {
      await _roomCubit!.leaveRoomSession(
        playerId: _currentPlayerId!,
        roomId: widget.roomId,
        isHost: _isHost!,
      );
    }

    if (mounted && context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await handleBackNavigation();
      },
      child: _RoomLifecycleInherited(
        playerId: _currentPlayerId,
        isHost: _isHost,
        roomCubit: _roomCubit,
        onUpdatePlayerInfo: updatePlayerInfo,
        child: widget.child,
      ),
    );
  }
}

class _RoomLifecycleInherited extends InheritedWidget {
  final String? playerId;
  final bool? isHost;
  final RoomCubit? roomCubit;
  final Function(String, bool) onUpdatePlayerInfo;

  const _RoomLifecycleInherited({
    required this.playerId,
    required this.isHost,
    required this.roomCubit,
    required this.onUpdatePlayerInfo,
    required super.child,
  });

  @override
  bool updateShouldNotify(_RoomLifecycleInherited old) {
    return playerId != old.playerId || isHost != old.isHost;
  }
}

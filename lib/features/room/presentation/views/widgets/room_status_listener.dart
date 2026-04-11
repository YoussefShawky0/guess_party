import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoomStatusListener extends StatefulWidget {
  final String roomId;
  final Widget Function(BuildContext context) builder;

  const RoomStatusListener({
    super.key,
    required this.roomId,
    required this.builder,
  });

  @override
  State<RoomStatusListener> createState() => _RoomStatusListenerState();
}

class _RoomStatusListenerState extends State<RoomStatusListener> {
  RealtimeChannel? _roomChannel;
  bool _isActive = true;

  void _unsubscribeFromRealtime() {
    _roomChannel?.unsubscribe();
    _roomChannel = null;
  }

  @override
  void initState() {
    super.initState();
    _listenToRoomStatus();
  }

  @override
  void deactivate() {
    // Prevent realtime callbacks from touching widget tree after deactivation.
    _isActive = false;
    _unsubscribeFromRealtime();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActive = true;
    if (_roomChannel == null) {
      _listenToRoomStatus();
    }
  }

  @override
  void dispose() {
    _isActive = false;
    _unsubscribeFromRealtime();
    super.dispose();
  }

  void _listenToRoomStatus() {
    if (!_isActive) return;

    try {
      _unsubscribeFromRealtime();

      final channel = Supabase.instance.client.channel(
        'room_status_${widget.roomId}',
      );

      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'rooms',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: widget.roomId,
        ),
        callback: (payload) {
          if (!_isActive || !mounted) return;

          final newStatus = payload.newRecord['status'];

          if (newStatus == 'finished' && mounted) {
            _handleRoomClosed();
          } else if (newStatus == 'active' && mounted) {
            _handleGameStarted();
          }
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.closed) {
          // Retry connection after a delay
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _isActive) {
              _unsubscribeFromRealtime();
              _listenToRoomStatus();
            }
          });
        }
      });

      _roomChannel = channel;
    } catch (e) {
      // Retry after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isActive) {
          _listenToRoomStatus();
        }
      });
    }
  }

  void _handleRoomClosed() {
    if (!_isActive || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Room has been closed. Returning to home.'),
        backgroundColor: AppColors.error,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isActive && context.mounted) {
        context.go(AppRoutes.home);
      }
    });
  }

  void _handleGameStarted() {
    // Navigate to countdown when game starts
    // No need to load players data when navigating away
    if (mounted && _isActive && context.mounted) {
      context.go(AppRoutes.roomCountdown(widget.roomId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

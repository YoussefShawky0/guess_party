import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    _listenToRoomStatus();
  }

  @override
  void dispose() {
    _roomChannel?.unsubscribe();
    super.dispose();
  }

  void _listenToRoomStatus() {
    try {
      final channel = Supabase.instance.client.channel('room_status_${widget.roomId}');
      
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
            if (mounted) {
              _roomChannel?.unsubscribe();
              _listenToRoomStatus();
            }
          });
        }
      });
      
      _roomChannel = channel;
    } catch (e) {
      // Retry after delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _listenToRoomStatus();
        }
      });
    }
  }

  void _handleRoomClosed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('المضيف غادر الغرفة. تم إغلاق الغرفة.'),
        backgroundColor: AppColors.error,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && context.mounted) {
        context.go('/home');
      }
    });
  }

  void _handleGameStarted() {
    // Navigate to countdown when game starts
    // No need to load players data when navigating away
    if (mounted && context.mounted) {
      context.go('/room/${widget.roomId}/countdown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    print('👂 Setting up room status listener for room: ${widget.roomId}');
    
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
        print('🔔 Room status changed: ${payload.newRecord}');
        final newStatus = payload.newRecord['status'];
        print('📊 New status: $newStatus');

        if (newStatus == 'finished' && mounted) {
          _handleRoomClosed();
        } else if (newStatus == 'active' && mounted) {
          _handleGameStarted();
        }
      },
    );
    
    channel.subscribe((status, error) {
      print('📡 Subscription status: $status, error: $error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('✅ Successfully subscribed to room status updates');
      } else if (status == RealtimeSubscribeStatus.closed) {
        print('❌ Subscription closed. Retrying...');
        // Retry connection after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _listenToRoomStatus();
          }
        });
      }
    });
    
    _roomChannel = channel;
  }

  void _handleRoomClosed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('المضيف غادر الغرفة. تم إغلاق الغرفة.'),
        backgroundColor: Colors.red,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && context.mounted) {
        context.go('/home');
      }
    });
  }

  void _handleGameStarted() {
    print('🎯 Game started, navigating to countdown');
    // Navigate to countdown when game starts
    // No need to load players data when navigating away
    if (mounted && context.mounted) {
      print('✅ Context is valid, navigating to: /room/${widget.roomId}/countdown');
      context.go('/room/${widget.roomId}/countdown');
    } else {
      print('❌ Context not mounted, cannot navigate');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

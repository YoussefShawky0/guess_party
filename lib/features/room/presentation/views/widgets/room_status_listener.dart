import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
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
    _roomChannel = Supabase.instance.client
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
            print('Room status changed: ${payload.newRecord}');
            final newStatus = payload.newRecord['status'];

            if (newStatus == 'finished' && mounted) {
              _handleRoomClosed();
            } else if (newStatus == 'active' && mounted) {
              _handleGameStarted();
            }
          },
        )
        .subscribe();
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
    context.read<RoomCubit>().loadRoomPlayers(roomId: widget.roomId);
    if (mounted && context.mounted) {
      context.push('/room/${widget.roomId}/countdown');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}

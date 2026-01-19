import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayersList extends StatefulWidget {
  final String roomId;

  const PlayersList({super.key, required this.roomId});

  @override
  State<PlayersList> createState() => _PlayersListState();
}

class _PlayersListState extends State<PlayersList> {
  @override
  void initState() {
    super.initState();
    context.read<RoomCubit>().loadRoomPlayers(roomId: widget.roomId);
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    Supabase.instance.client
        .channel('players_${widget.roomId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'players',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: widget.roomId,
          ),
          callback: (payload) {
            if (mounted) {
              context.read<RoomCubit>().loadRoomPlayers(roomId: widget.roomId);
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    Supabase.instance.client.removeChannel(
      Supabase.instance.client.channel('players_${widget.roomId}'),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocBuilder<RoomCubit, RoomState>(
          builder: (context, state) {
            final playerCount =
                (state is RoomDetailsLoaded && state.players != null)
                ? state.players!.length
                : 0;
            final maxPlayers = (state is RoomDetailsLoaded)
                ? state.room.maxPlayers
                : 6;

            return Row(
              children: [
                Text(
                  'Players',
                  style: TextStyle(
                    fontSize: isTablet ? 24 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$playerCount/$maxPlayers',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BlocBuilder<RoomCubit, RoomState>(
              builder: (context, state) {
                if (state is RoomDetailsLoaded && state.players != null) {
                  if (state.players!.isEmpty) {
                    return const Center(child: Text('No players yet'));
                  }

                  return ListView.separated(
                    itemCount: state.players!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = state.players![index];
                      return Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isTablet ? 28 : 24,
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: isTablet ? 28 : 24,
                              ),
                            ),
                            SizedBox(width: isTablet ? 16 : 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    player.username,
                                    style: TextStyle(
                                      fontSize: isTablet ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (player.isHost)
                                    Text(
                                      'Host',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 16 : 12,
                                vertical: isTablet ? 8 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: player.isOnline
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                player.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: player.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ],
    );
  }
}

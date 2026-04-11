import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlayersList extends StatefulWidget {
  final String roomId;

  const PlayersList({super.key, required this.roomId});

  @override
  State<PlayersList> createState() => _PlayersListState();
}

class _PlayersListState extends State<PlayersList> {
  RealtimeChannel? _playersChannel;
  Timer? _pollTimer;

  late final RoomCubit _roomCubit;
  bool _isActive = true;

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshPlayers();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _unsubscribeFromRealtime() {
    _playersChannel?.unsubscribe();
    _playersChannel = null;
  }

  void _refreshPlayers() {
    if (!_isActive || !mounted) return;
    if (_roomCubit.isClosed) return;
    _roomCubit.loadRoomPlayers(roomId: widget.roomId);
  }

  @override
  void initState() {
    super.initState();

    // Cache cubit reference to avoid ancestor lookup from async callbacks.
    _roomCubit = context.read<RoomCubit>();

    _refreshPlayers();
    _subscribeToRealtimeUpdates();
    // Fallback in case realtime drops or misses events.
    _startPolling();
  }

  void _subscribeToRealtimeUpdates() {
    if (!_isActive) return;

    // Ensure we don't create duplicate subscriptions.
    _unsubscribeFromRealtime();

    try {
      final channel = Supabase.instance.client
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
              _refreshPlayers();
            },
          );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.closed) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _isActive) {
              _unsubscribeFromRealtime();
              _subscribeToRealtimeUpdates();
            }
          });
        }
      });

      _playersChannel = channel;
    } catch (_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isActive) _subscribeToRealtimeUpdates();
      });
    }
  }

  @override
  void deactivate() {
    // Prevent async callbacks (timer/realtime) from touching widget tree.
    _isActive = false;
    _stopPolling();
    _unsubscribeFromRealtime();
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _isActive = true;
    _refreshPlayers();
    _subscribeToRealtimeUpdates();
    _startPolling();
  }

  @override
  void dispose() {
    _isActive = false;
    _stopPolling();
    _unsubscribeFromRealtime();
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
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$playerCount/$maxPlayers',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
              color: AppColors.of(context).surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BlocBuilder<RoomCubit, RoomState>(
              builder: (context, state) {
                if (state is RoomDetailsLoaded && state.players != null) {
                  if (state.players!.isEmpty) {
                    return Center(
                      child: Text(
                        'No players yet',
                        style: TextStyle(
                          color: AppColors.of(context).textSecondary,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: state.players!.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final player = state.players![index];
                      return Container(
                        padding: EdgeInsets.all(isTablet ? 20 : 16),
                        decoration: BoxDecoration(
                          color: AppColors.of(context).surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isTablet ? 28 : 24,
                              backgroundColor: AppColors.primary,
                              child: FaIcon(
                                FontAwesomeIcons.user,
                                color: AppColors.of(context).textPrimary,
                                size: isTablet ? 22 : 18,
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
                                      color: AppColors.of(context).textPrimary,
                                    ),
                                  ),
                                  if (player.isHost)
                                    Text(
                                      'Host',
                                      style: TextStyle(
                                        fontSize: isTablet ? 16 : 14,
                                        color: AppColors.primaryLight,
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
                                    ? AppColors.success.withValues(alpha: 0.2)
                                    : AppColors.of(
                                        context,
                                      ).textSecondary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                player.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: player.isOnline
                                      ? AppColors.success
                                      : AppColors.of(context).textSecondary,
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

                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

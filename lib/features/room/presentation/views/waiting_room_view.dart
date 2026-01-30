import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'widgets/room_lifecycle_manager.dart';
import 'widgets/room_status_listener.dart';
import 'widgets/waiting_room_app_bar.dart';
import 'widgets/waiting_room_body.dart';

class WaitingRoomView extends StatelessWidget {
  final String roomId;

  const WaitingRoomView({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<RoomCubit>()..loadRoomDetails(roomId: roomId),
      child: WaitingRoomContent(roomId: roomId),
    );
  }
}

class WaitingRoomContent extends StatefulWidget {
  final String roomId;

  const WaitingRoomContent({super.key, required this.roomId});

  @override
  State<WaitingRoomContent> createState() => _WaitingRoomContentState();
}

class _WaitingRoomContentState extends State<WaitingRoomContent> {
  String? _currentPlayerId;
  bool? _isHost;

  void _updatePlayerInfo(String playerId, bool isHost) {
    setState(() {
      _currentPlayerId = playerId;
      _isHost = isHost;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoomLifecycleManager(
      roomId: widget.roomId,
      onPlayerIdentified: _updatePlayerInfo,
      child: RoomStatusListener(
        roomId: widget.roomId,
        builder: (context) => _buildScaffold(),
      ),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: WaitingRoomAppBar(
        currentPlayerId: _currentPlayerId ?? '',
        roomId: widget.roomId,
        isHost: _isHost ?? false,
        roomCubit: context.read<RoomCubit>(),
      ),
      body: BlocConsumer<RoomCubit, RoomState>(
        listener: (context, state) {
          if (state is RoomError) {
            ErrorSnackBar.show(context, state.message);
          }

          if (state is RoomDetailsLoaded && state.room.status == 'finished') {
            if (_isHost != true) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('المضيف غادر الغرفة. تم إغلاق الغرفة.'),
                  backgroundColor: AppColors.error,
                ),
              );
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted && context.mounted) {
                  context.go('/home');
                }
              });
            }
          }
        },
        builder: (context, state) {
          if (state is RoomLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is RoomDetailsLoaded) {
            final currentUser = Supabase.instance.client.auth.currentUser;
            final players = state.players ?? [];

            // Find current player safely - avoid firstWhere type mismatch
            Player? currentPlayer;
            if (players.isNotEmpty && currentUser != null) {
              // Use loop instead of firstWhere to avoid Player/PlayerModel generic issue
              for (final player in players) {
                if (player.userId == currentUser.id) {
                  currentPlayer = player;
                  break;
                }
              }
              // Fallback to first player if current user not found
              currentPlayer ??= players.first;
            }

            // Update player info for lifecycle management
            if (currentPlayer != null && _currentPlayerId == null) {
              final playerId = currentPlayer.id;
              final isHost = currentPlayer.isHost;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updatePlayerInfo(playerId, isHost);
              });
            }

            final isHost =
                currentPlayer?.isHost == true &&
                currentPlayer?.userId == currentUser?.id;
            final playerCount = players.length;

            return WaitingRoomBody(
              roomId: widget.roomId,
              roomCode: state.room.roomCode,
              isHost: isHost,
              playerCount: playerCount,
              onStartGame: () {
                context.read<RoomCubit>().startGameSession(widget.roomId);
              },
            );
          }

          return const Center(child: Text('حدث خطأ ما'));
        },
      ),
    );
  }
}

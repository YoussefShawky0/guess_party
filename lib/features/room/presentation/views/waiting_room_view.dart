import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/auth_session_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/error_snackbar.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'widgets/room_lifecycle_manager.dart';
import 'widgets/waiting_room_app_bar.dart';
import 'widgets/waiting_room_body.dart';

class WaitingRoomView extends StatelessWidget {
  final String roomId;
  final RoomCubit? roomCubit;
  final String? Function()? currentUserIdResolver;
  final Widget Function(String roomId)? playersListBuilder;

  const WaitingRoomView({
    super.key,
    required this.roomId,
    this.roomCubit,
    this.currentUserIdResolver,
    this.playersListBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final providedCubit = roomCubit;
    if (providedCubit != null) {
      return BlocProvider.value(
        value: providedCubit,
        child: WaitingRoomContent(
          roomId: roomId,
          currentUserIdResolver: currentUserIdResolver,
          playersListBuilder: playersListBuilder,
        ),
      );
    }

    return BlocProvider(
      create: (context) => di.sl<RoomCubit>()
        ..loadRoomDetails(roomId: roomId)
        ..watchRoomStatus(roomId: roomId),
      child: WaitingRoomContent(
        roomId: roomId,
        currentUserIdResolver: currentUserIdResolver,
        playersListBuilder: playersListBuilder,
      ),
    );
  }
}

class WaitingRoomContent extends StatefulWidget {
  final String roomId;
  final String? Function()? currentUserIdResolver;
  final Widget Function(String roomId)? playersListBuilder;

  const WaitingRoomContent({
    super.key,
    required this.roomId,
    this.currentUserIdResolver,
    this.playersListBuilder,
  });

  @override
  State<WaitingRoomContent> createState() => _WaitingRoomContentState();
}

class _WaitingRoomContentState extends State<WaitingRoomContent> {
  String? _currentPlayerId;
  bool? _isHost;
  bool _hasNavigatedToCountdown = false;
  bool _hasHandledFinishedRoom = false;

  void _updatePlayerInfo(String playerId, bool isHost) {
    setState(() {
      _currentPlayerId = playerId;
      _isHost = isHost;
    });
  }

  void _goToCountdownOnce(BuildContext context) {
    if (_hasNavigatedToCountdown || !mounted) {
      return;
    }

    _hasNavigatedToCountdown = true;
    context.go(AppRoutes.roomCountdown(widget.roomId));
  }

  void _handleRoomFinishedOnce(BuildContext context) {
    if (_hasHandledFinishedRoom || !mounted) {
      return;
    }

    _hasHandledFinishedRoom = true;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.hostClosedRoom),
        backgroundColor: AppColors.error,
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        router.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RoomLifecycleManager(
      roomId: widget.roomId,
      onPlayerIdentified: _updatePlayerInfo,
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppColors.of(context).background,
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

          if (state is RoomDetailsLoaded && state.room.status == 'active') {
            _goToCountdownOnce(context);
          }

          if (state is RoomDetailsLoaded &&
              state.room.status == 'finished' &&
              _isHost != true) {
            _handleRoomFinishedOnce(context);
          }
        },
        builder: (context, state) {
          if (state is RoomLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is RoomDetailsLoaded) {
            final currentUserId = widget.currentUserIdResolver != null
                ? widget.currentUserIdResolver!()
                : _resolveCurrentUserId();
            final players = state.players ?? [];

            // Find current player safely - avoid firstWhere type mismatch
            Player? currentPlayer;
            if (players.isNotEmpty && currentUserId != null) {
              // Use loop instead of firstWhere to avoid Player/PlayerModel generic issue
              for (final player in players) {
                if (player.userId == currentUserId) {
                  currentPlayer = player;
                  break;
                }
              }
            }

            if (currentUserId == null || currentPlayer == null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Syncing your player...',
                      style: TextStyle(
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Update player info for lifecycle management
            if (_currentPlayerId == null) {
              final playerId = currentPlayer.id;
              final isHost = currentPlayer.isHost;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _updatePlayerInfo(playerId, isHost);
              });
            }

            final isHost =
                currentPlayer.isHost && currentPlayer.userId == currentUserId;
            final playerCount = players.length;

            return WaitingRoomBody(
              roomId: widget.roomId,
              roomCode: state.room.roomCode,
              isHost: isHost,
              playerCount: playerCount,
              playersListBuilder: widget.playersListBuilder,
              onStartGame: () {
                context.read<RoomCubit>().startGameSession(widget.roomId);
              },
            );
          }

          return Center(child: Text(context.l10n.somethingWentWrong));
        },
      ),
    );
  }

  String? _resolveCurrentUserId() {
    try {
      return di.sl<AuthSessionService>().currentUserId;
    } catch (_) {
      return null;
    }
  }
}

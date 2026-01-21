import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';
import 'package:guess_party/shared/widgets/app_bar_title.dart';

class WaitingRoomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? currentPlayerId;
  final String roomId;
  final bool? isHost;
  final RoomCubit? roomCubit;

  const WaitingRoomAppBar({
    super.key,
    required this.currentPlayerId,
    required this.roomId,
    required this.isHost,
    required this.roomCubit,
  });

  Future<void> _handleBackPress(BuildContext context) async {
    if (currentPlayerId != null && isHost != null && roomCubit != null) {
      await roomCubit!.leaveRoomSession(
        playerId: currentPlayerId!,
        roomId: roomId,
        isHost: isHost!,
      );
    }

    if (context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const AppBarTitle(title: 'Waiting Room'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBackPress(context),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

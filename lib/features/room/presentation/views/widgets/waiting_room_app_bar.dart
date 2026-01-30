import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
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
      backgroundColor: AppColors.surface,
      title: const AppBarTitle(title: 'Waiting Room'),
      centerTitle: true,
      leading: IconButton(
        icon: FaIcon(FontAwesomeIcons.arrowLeftLong, color: AppColors.textPrimary, size: 20),
        onPressed: () => _handleBackPress(context),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

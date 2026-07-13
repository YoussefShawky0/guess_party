import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/features/room/presentation/cubit/room_cubit.dart';

class PlayersList extends StatelessWidget {
  final String roomId;

  const PlayersList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    return BlocBuilder<RoomCubit, RoomState>(
      builder: (context, state) {
        final players = state is RoomDetailsLoaded
            ? state.players ?? const []
            : const [];
        final maxPlayers = state is RoomDetailsLoaded
            ? state.room.maxPlayers
            : 6;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                    '${players.length}/$maxPlayers',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: state is! RoomDetailsLoaded
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : players.isEmpty
                    ? Center(
                        child: Text(
                          'No players yet',
                          style: TextStyle(
                            color: AppColors.of(context).textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: players.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final player = players[index];
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.username,
                                        style: TextStyle(
                                          fontSize: isTablet ? 20 : 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.of(
                                            context,
                                          ).textPrimary,
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
                                        ? AppColors.success.withValues(
                                            alpha: 0.2,
                                          )
                                        : AppColors.of(context).textSecondary
                                              .withValues(alpha: 0.2),
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
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

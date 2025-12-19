import 'package:flutter/material.dart';
import 'package:guess_party/features/room/presentation/views/widgets/players_list.dart';
import 'package:guess_party/features/room/presentation/views/widgets/room_code_card.dart';
import 'package:guess_party/features/room/presentation/views/widgets/share_room_button.dart';
import 'package:guess_party/features/room/presentation/views/widgets/start_game_button.dart';

class WaitingRoomBody extends StatelessWidget {
  final String roomId;
  final String roomCode;
  final bool isHost;
  final int playerCount;
  final VoidCallback onStartGame;

  const WaitingRoomBody({
    super.key,
    required this.roomId,
    required this.roomCode,
    required this.isHost,
    required this.playerCount,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? size.width * 0.15 : 24,
          vertical: 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RoomCodeCard(roomCode: roomCode),
            SizedBox(height: isTablet ? 24 : 20),
            ShareRoomButton(roomCode: roomCode),
            SizedBox(height: isTablet ? 32 : 24),
            Expanded(child: PlayersList(roomId: roomId)),
            if (isHost) ...[
              SizedBox(height: isTablet ? 24 : 20),
              StartGameButton(
                roomId: roomId,
                onPressed: onStartGame,
                isEnabled: true,
                playerCount: playerCount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:guess_party/features/room/presentation/views/widgets/players_list.dart';
import 'package:guess_party/features/room/presentation/views/widgets/room_code_card.dart';
import 'package:guess_party/features/room/presentation/views/widgets/share_room_button.dart';
import 'package:guess_party/features/room/presentation/views/widgets/start_game_button.dart';

class WaitingRoomBody extends StatefulWidget {
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
  State<WaitingRoomBody> createState() => _WaitingRoomBodyState();
}

class _WaitingRoomBodyState extends State<WaitingRoomBody> {
  bool _isStarting = false;

  void _handleStartGame() {
    if (_isStarting) return;

    setState(() {
      _isStarting = true;
    });

    widget.onStartGame();

    // Reset after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isStarting = false;
        });
      }
    });
  }

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
            RoomCodeCard(roomCode: widget.roomCode),
            SizedBox(height: isTablet ? 24 : 20),
            ShareRoomButton(roomCode: widget.roomCode),
            SizedBox(height: isTablet ? 32 : 24),
            Expanded(child: PlayersList(roomId: widget.roomId)),
            if (widget.isHost) ...[
              SizedBox(height: isTablet ? 24 : 20),
              StartGameButton(
                roomId: widget.roomId,
                onPressed: _handleStartGame,
                isEnabled: !_isStarting,
                playerCount: widget.playerCount,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

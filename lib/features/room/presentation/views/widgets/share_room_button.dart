import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareRoomButton extends StatelessWidget {
  final String roomCode;

  const ShareRoomButton({super.key, required this.roomCode});

  Future<void> _shareRoomCode() async {
    final params = ShareParams(
      text:
          '''
🎉 Join my Guess Party room!

Room Code: *$roomCode*

Enter this code in the app to join the game!
    ''',
    );
    SharePlus.instance.share(params);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return ElevatedButton.icon(
      onPressed: _shareRoomCode,
      icon: Icon(Icons.share, size: isTablet ? 24 : 20),
      label: Text(
        'Share Room Code',
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: isTablet ? 18 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

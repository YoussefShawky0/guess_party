import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
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
      icon: FaIcon(FontAwesomeIcons.shareFromSquare, size: isTablet ? 20 : 16),
      label: Text(
        'Share Room Code',
        style: TextStyle(
          fontSize: isTablet ? 18 : 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 32 : 24,
          vertical: isTablet ? 18 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

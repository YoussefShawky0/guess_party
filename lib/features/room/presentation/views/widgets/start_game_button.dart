import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class StartGameButton extends StatelessWidget {
  final String roomId;
  final VoidCallback onPressed;
  final bool isEnabled;
  final int playerCount;

  const StartGameButton({
    super.key,
    required this.roomId,
    required this.onPressed,
    required this.isEnabled,
    required this.playerCount,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final minPlayers = 4;
    final needMorePlayers = playerCount < minPlayers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isEnabled && !needMorePlayers
              ? () {
                  onPressed();
                  // Navigation is handled by RoomStatusListener via realtime updates
                }
              : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: isTablet ? 20 : 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textPrimary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(FontAwesomeIcons.play, size: isTablet ? 24 : 20),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Start Game',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (needMorePlayers) ...[
          const SizedBox(height: 8),
          Text(
            'Need ${minPlayers - playerCount} more player${minPlayers - playerCount > 1 ? 's' : ''} to start',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

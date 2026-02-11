import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class RoomCodeCard extends StatelessWidget {
  final String roomCode;

  const RoomCodeCard({super.key, required this.roomCode});

  void _copyRoomCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: roomCode));
    // Room code copied silently
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 40 : 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Room Code',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Room Code Display
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 32 : 24,
              vertical: isTablet ? 20 : 16,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              roomCode,
              style: TextStyle(
                fontSize: isTablet ? 56 : 48,
                fontWeight: FontWeight.bold,
                letterSpacing: isTablet ? 12 : 8,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Copy Button
          TextButton.icon(
            onPressed: () => _copyRoomCode(context),
            icon: FaIcon(
              FontAwesomeIcons.copy,
              size: 16,
              color: AppColors.primary,
            ),
            label: Text(
              'Copy Code',
              style: TextStyle(color: AppColors.primary),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

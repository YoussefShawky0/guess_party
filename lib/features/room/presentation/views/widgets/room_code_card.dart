import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

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
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            context.l10n.roomCode,
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              color: AppColors.of(context).textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Room Code Display
          Semantics(
            label: '${context.l10n.roomCode}: $roomCode',
            child: Container(
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
              context.l10n.copyCode,
              style: TextStyle(color: AppColors.primary),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class CreateRoomHeader extends StatelessWidget {
  const CreateRoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 24 : 20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            FontAwesomeIcons.igloo,
            size: isTablet ? 48 : 36,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Text(
          'Create New Room',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          'Choose category and rounds to start the game',
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

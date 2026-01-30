import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';

class JoinRoomHeader extends StatelessWidget {
  const JoinRoomHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Column(
      children: [
        FaIcon(
          FontAwesomeIcons.userPlus,
          size: isTablet ? 80 : 64,
          color: AppColors.primary,
        ),
        SizedBox(height: isTablet ? 40 : 32),
        Text(
          'Enter Room Code',
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

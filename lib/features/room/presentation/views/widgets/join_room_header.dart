import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';

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
          context.l10n.enterRoomCode,
          style: TextStyle(
            fontSize: isTablet ? 32 : 28,
            fontWeight: FontWeight.bold,
            color: AppColors.of(context).textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

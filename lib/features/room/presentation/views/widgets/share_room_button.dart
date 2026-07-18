import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:share_plus/share_plus.dart';
import 'package:guess_party/l10n/l10n.dart';

class ShareRoomButton extends StatelessWidget {
  final String roomCode;

  const ShareRoomButton({super.key, required this.roomCode});

  Future<void> _shareRoomCode(BuildContext context) async {
    final params = ShareParams(text: context.l10n.shareRoomMessage(roomCode));
    SharePlus.instance.share(params);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Semantics(
      button: true,
      label: context.l10n.shareRoomCode,
      child: ElevatedButton.icon(
        onPressed: () => _shareRoomCode(context),
        icon: FaIcon(
          FontAwesomeIcons.shareFromSquare,
          size: isTablet ? 20 : 16,
        ),
        label: Text(
          context.l10n.shareRoomCode,
          style: TextStyle(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.of(context).textPrimary,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 32 : 24,
            vertical: isTablet ? 18 : 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

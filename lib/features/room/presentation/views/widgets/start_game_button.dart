import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';

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
        GameButton(
          onPressed: isEnabled && !needMorePlayers
              ? () {
                  onPressed();
                  // Navigation is handled by the waiting-room Cubit status stream.
                }
              : null,
          icon: const FaIcon(FontAwesomeIcons.play),
          label: context.l10n.startGame,
          semanticHint: context.l10n.startGameHint,
        ),
        if (needMorePlayers) ...[
          const SizedBox(height: 8),
          Text(
            context.l10n.playersNeededToStart(minPlayers - playerCount),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.of(context).textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

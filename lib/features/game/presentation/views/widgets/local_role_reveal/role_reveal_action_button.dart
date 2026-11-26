import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/shared/design/game_button.dart';
import 'package:guess_party/shared/widgets/directional_fa_icon.dart';
import 'package:guess_party/l10n/l10n.dart';

/// Reveal / next player / start game button.
class RoleRevealActionButton extends StatelessWidget {
  final bool isRoleRevealed;
  final bool isLastPlayer;
  final bool isTablet;
  final VoidCallback onPressed;

  const RoleRevealActionButton({
    super.key,
    required this.isRoleRevealed,
    required this.isLastPlayer,
    required this.isTablet,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Only the "next player" arrow is directional; play and eye are not.
    // GameButton sizes and colors the icon through IconTheme.
    final Widget icon = isRoleRevealed && !isLastPlayer
        ? const DirectionalFaIcon(FontAwesomeIcons.arrowRight)
        : FaIcon(isRoleRevealed ? FontAwesomeIcons.play : FontAwesomeIcons.eye);

    return GameButton(
      label: isRoleRevealed
          ? (isLastPlayer
                ? context.l10n.startGameExclamation
                : context.l10n.nextPlayer)
          : context.l10n.revealMyRole,
      icon: icon,
      onPressed: onPressed,
    );
  }
}

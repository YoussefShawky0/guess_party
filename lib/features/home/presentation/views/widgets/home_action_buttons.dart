import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/how_to_play_dialog.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_button.dart';
import 'package:guess_party/shared/widgets/directional_fa_icon.dart';

/// The two Home actions and the small "How to play" link.
class HomeActionButtons extends StatelessWidget {
  final bool isTablet;

  const HomeActionButtons({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameButton(
          label: context.l10n.createRoom,
          icon: const FaIcon(FontAwesomeIcons.plus),
          onPressed: () => context.push(AppRoutes.createRoom),
        ),
        SizedBox(height: isTablet ? 20 : 16),
        GameButton(
          variant: GameButtonVariant.secondary,
          label: context.l10n.joinRoom,
          icon: const DirectionalFaIcon(FontAwesomeIcons.rightToBracket),
          onPressed: () => context.push(AppRoutes.joinRoom),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        TextButton(
          key: const Key('home-how-to-play-button'),
          onPressed: () => showHowToPlayDialog(context: context),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.of(context).textSecondary,
            minimumSize: const Size(48, 48),
          ),
          child: Text(context.l10n.howToPlay),
        ),
      ],
    );
  }
}

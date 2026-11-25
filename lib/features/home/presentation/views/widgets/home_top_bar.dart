import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/game_chip.dart';
import 'package:guess_party/shared/design/game_icon_button.dart';
import 'package:guess_party/shared/design/player_avatar.dart';

/// Profile chip, trophy chip and the settings button.
///
/// [userInfo] is null while Home is still loading: only settings shows then.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.userInfo,
    required this.summary,
    required this.onProfile,
    required this.onTrophy,
    required this.onSettings,
  });

  final UserInfo? userInfo;
  final BadgeSummary? summary;
  final VoidCallback onProfile;
  final VoidCallback onTrophy;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = GameTokens.of(context);
    final user = userInfo;
    final summary = this.summary;

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        tokens.spacing.lg,
        tokens.spacing.sm,
        tokens.spacing.lg,
        0,
      ),
      child: Row(
        children: [
          if (user != null) ...[
            // The profile chip takes all the free width, so a username is
            // truncated only when it really doesn't fit.
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GameChip(
                  key: const Key('home-profile-chip'),
                  onTap: onProfile,
                  semanticLabel: '${l10n.profileTitle}: ${user.username}',
                  icon: PlayerAvatar(
                    name: user.username,
                    size: 28,
                    showDot: user.isAnonymous || user.isLegacyAccount,
                  ),
                  label: user.username,
                ),
              ),
            ),
            SizedBox(width: tokens.spacing.sm),
            GameChip(
              key: const Key('home-trophy-chip'),
              onTap: onTrophy,
              background: tokens.reward.gold,
              foreground: AppColors.textDark,
              edge: tokens.reward.edge,
              icon: const FaIcon(FontAwesomeIcons.trophy),
              label: summary == null
                  ? null
                  : '${summary.unlocked}/${summary.total}',
              semanticLabel: summary == null
                  ? l10n.statsTitle
                  : l10n.badgeCountSemantics(summary.unlocked, summary.total),
            ),
            SizedBox(width: tokens.spacing.sm),
          ] else
            const Spacer(),
          GameIconButton(
            key: const Key('home-settings-button'),
            icon: const FaIcon(FontAwesomeIcons.gear),
            tooltip: l10n.settings,
            onPressed: onSettings,
          ),
        ],
      ),
    );
  }
}

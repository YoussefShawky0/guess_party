import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/design/game_tokens.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/player_avatar.dart';
import 'package:guess_party/shared/widgets/directional_fa_icon.dart';

/// What the player picked in the profile sheet. The sheet only reports the
/// choice; the Home screen acts on it after the sheet is closed.
enum ProfileAction { secureAccount, stats, logout }

Future<ProfileAction?> showProfileSheet({
  required BuildContext context,
  required UserInfo userInfo,
  required BadgeSummary? summary,
}) {
  return showModalBottomSheet<ProfileAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.of(context).surface,
    builder: (_) => ProfileSheet(userInfo: userInfo, summary: summary),
  );
}

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({
    super.key,
    required this.userInfo,
    required this.summary,
  });

  final UserInfo userInfo;
  final BadgeSummary? summary;

  bool get _canSecure => userInfo.isAnonymous || userInfo.isLegacyAccount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = GameTokens.of(context);
    final colors = AppColors.of(context);
    final summary = this.summary;

    void pick(ProfileAction action) => Navigator.of(context).pop(action);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsetsDirectional.fromSTEB(
          tokens.spacing.xl,
          0,
          tokens.spacing.xl,
          tokens.spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PlayerAvatar(
                  name: userInfo.username,
                  size: 56,
                  showDot: _canSecure,
                ),
                SizedBox(width: tokens.spacing.lg),
                Expanded(
                  child: Text(
                    userInfo.username,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: colors.textPrimary),
                  ),
                ),
              ],
            ),
            if (summary != null) ...[
              SizedBox(height: tokens.spacing.xl),
              Row(
                key: const Key('profile-mini-stats'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MiniStat(
                      value: '${summary.gamesPlayed}',
                      label: l10n.statsGames,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      value: '${summary.gamesWon}',
                      label: l10n.statsWins,
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      value: '${summary.unlocked}/${summary.total}',
                      label: l10n.badgesTitle,
                    ),
                  ),
                ],
              ),
            ],
            SizedBox(height: tokens.spacing.lg),
            if (_canSecure)
              _Row(
                key: const Key('profile-secure'),
                icon: const FaIcon(FontAwesomeIcons.shieldHalved),
                label: userInfo.isAnonymous
                    ? l10n.secureGuestAccount
                    : l10n.linkRecoveryEmail,
                onTap: () => pick(ProfileAction.secureAccount),
              ),
            _Row(
              key: const Key('profile-stats'),
              icon: const FaIcon(FontAwesomeIcons.chartSimple),
              label: l10n.statsTitle,
              onTap: () => pick(ProfileAction.stats),
            ),
            _Row(
              key: const Key('profile-logout'),
              icon: const DirectionalFaIcon(FontAwesomeIcons.rightFromBracket),
              label: l10n.logout,
              color: AppColors.error,
              onTap: () => pick(ProfileAction.logout),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: colors.textPrimary),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.of(context).textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GameTokens.of(context).radius.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            IconTheme.merge(
              data: IconThemeData(color: fg, size: 18),
              child: SizedBox(width: 24, child: Center(child: icon)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: TextStyle(color: fg, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

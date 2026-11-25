import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/widgets/error_screen.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/presentation/badge_visuals.dart';
import 'package:guess_party/features/stats/presentation/cubit/player_stats_cubit.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/animated_game_background.dart';

/// Lifetime stats and badges. Needs a [PlayerStatsCubit] above it.
class StatsView extends StatelessWidget {
  /// Guests see a card inviting them to secure their account.
  final bool isGuest;

  const StatsView({super.key, this.isGuest = false});

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerStatsCubit, PlayerStatsState>(
      builder: (context, state) {
        if (state is StatsFailed) {
          return ErrorScreen(
            message: localizedErrorMessage(context.l10n, state.code),
            onRetry: () => context.read<PlayerStatsCubit>().load(),
            onGoBack: () => _leave(context),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.of(context).background,
          appBar: AppBar(
            title: Text(context.l10n.statsTitle),
            backgroundColor: AppColors.of(context).background,
            foregroundColor: AppColors.of(context).textPrimary,
            elevation: 0,
          ),
          body: AnimatedGameBackground(
            child: switch (state) {
              StatsLoaded() => _StatsBody(state: state, isGuest: isGuest),
              _ => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            },
          ),
        );
      },
    );
  }
}

class _StatsBody extends StatelessWidget {
  final StatsLoaded state;
  final bool isGuest;

  const _StatsBody({required this.state, required this.isGuest});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = state.stats;
    return RefreshIndicator(
      onRefresh: () => context.read<PlayerStatsCubit>().load(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isGuest) ...[
                    const _GuestCard(),
                    const SizedBox(height: 16),
                  ],
                  _TwoColumns(
                    children: [
                      _StatTile(
                        icon: FontAwesomeIcons.gamepad,
                        label: l10n.statsGames,
                        value: s.gamesPlayed,
                      ),
                      _StatTile(
                        icon: FontAwesomeIcons.trophy,
                        label: l10n.statsWins,
                        value: s.gamesWon,
                      ),
                      _StatTile(
                        icon: FontAwesomeIcons.rotate,
                        label: l10n.statsRounds,
                        value: s.roundsPlayed,
                      ),
                      _StatTile(
                        icon: FontAwesomeIcons.userSecret,
                        label: l10n.statsAsImposter,
                        value: s.roundsAsImposter,
                      ),
                      _StatTile(
                        icon: FontAwesomeIcons.personRunning,
                        label: l10n.statsEscapes,
                        value: s.imposterEscapes,
                      ),
                      _StatTile(
                        icon: FontAwesomeIcons.circleCheck,
                        label: l10n.statsCorrectVotes,
                        value: s.correctVotes,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.badgesTitle,
                    style: TextStyle(
                      color: AppColors.of(context).textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TwoColumns(
                    children: [
                      for (final badge in state.badges)
                        _BadgeTile(badge: badge),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays children out in two equal columns without fixing their height, so
/// large text sizes never overflow.
class _TwoColumns extends StatelessWidget {
  final List<Widget> children;

  const _TwoColumns({required this.children});

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final int value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, size: 18, color: AppColors.primaryLight),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeProgress badge;

  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final l10n = context.l10n;
    final unlocked = badge.unlocked;
    final accent = unlocked ? AppColors.goldMedal : colors.textMuted;
    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
        key: Key('badge-${badge.id.name}'),
        padding: const EdgeInsetsDirectional.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unlocked
                ? AppColors.goldMedal.withValues(alpha: 0.7)
                : colors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FaIcon(
              badge.id.icon,
              size: 24,
              color: unlocked ? AppColors.goldMedal : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              badge.id.localizedName(l10n),
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              badge.id.localizedDescription(l10n),
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: badge.current / badge.target,
                  minHeight: 6,
                  color: accent,
                  backgroundColor: colors.cardBorder,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${badge.current}/${badge.target}',
                style: TextStyle(color: colors.textMuted, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      key: const Key('stats-guest-card'),
      padding: const EdgeInsetsDirectional.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.statsGuestCardTitle,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('stats-guest-upgrade'),
            onPressed: () => context.push(AppRoutes.accountUpgrade),
            icon: const Icon(Icons.mark_email_read_outlined),
            label: Text(context.l10n.secureGuestAccount),
          ),
        ],
      ),
    );
  }
}

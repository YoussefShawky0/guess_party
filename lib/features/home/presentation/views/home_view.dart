import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/error/app_error_localizer.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/update_service.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';
import 'package:guess_party/features/stats/data/shared_prefs_badge_summary_store.dart';
import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:guess_party/features/stats/presentation/cubit/badge_summary_cubit.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:guess_party/shared/design/animated_game_background.dart';
import 'package:guess_party/shared/design/game_button.dart';

import 'widgets/guest_banner.dart';
import 'widgets/home_action_buttons.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/profile_sheet.dart';

enum _GuestLogoutChoice { secure, logOut }

class HomeView extends StatefulWidget {
  const HomeView({
    required this.config,
    this.bannerStore = const SharedPrefsBadgeSummaryStore(),
    super.key,
  });

  final AppConfig config;

  /// Remembers a dismissed "secure your account" banner, per user.
  final GuestBannerStore bannerStore;

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  // Check for app updates using the UpdateService
  Future<void> _checkForUpdates() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(seconds: 2));

    final updateInfo = await UpdateService.checkForUpdate(widget.config);

    if (!mounted) return;

    if (updateInfo?.updateAvailability == UpdateAvailability.updateAvailable) {
      if (updateInfo!.flexibleUpdateAllowed) {
        _showUpdateDialog();
      }
    }
  }

  // Show a dialog prompting the user to update the app
  void _showUpdateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            Text(
              context.l10n.updateAvailable,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: Text(
          context.l10n.updateAvailableMessage,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.later,
              style: TextStyle(color: AppColors.of(context).textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              UpdateService.startFlexibleUpdate(widget.config);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.l10n.update),
          ),
        ],
      ),
    );
  }

  Future<void> _openProfile(UserInfo user, BadgeSummary? summary) async {
    // Capture everything we need from this context before the first await.
    final homeCubit = context.read<HomeCubit>();
    final router = GoRouter.of(context);

    final action = await showProfileSheet(
      context: context,
      userInfo: user,
      summary: summary,
    );
    if (!mounted || action == null) return;

    switch (action) {
      case ProfileAction.secureAccount:
        router.push(AppRoutes.accountUpgrade);
      case ProfileAction.stats:
        router.push(AppRoutes.stats);
      case ProfileAction.logout:
        await _logout(user, homeCubit, router);
    }
  }

  Future<void> _logout(
    UserInfo user,
    HomeCubit homeCubit,
    GoRouter router,
  ) async {
    if (!user.isAnonymous) {
      await homeCubit.signOutUser();
      return;
    }

    // A guest cannot get this account back: confirm first. Barrier tap and
    // back both cancel.
    final choice = await showDialog<_GuestLogoutChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.of(dialogContext).surface,
        // Both choices live in the content column (not `actions`), so they
        // stack centered and full width instead of an end-aligned bar.
        contentPadding: const EdgeInsetsDirectional.fromSTEB(24, 24, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dialogContext.l10n.guestLogoutWarning,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(dialogContext).textPrimary),
            ),
            const SizedBox(height: 20),
            GameButton(
              key: const Key('guest-logout-secure'),
              label: dialogContext.l10n.secureAccount,
              size: GameButtonSize.md,
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_GuestLogoutChoice.secure),
            ),
            const SizedBox(height: 4),
            TextButton(
              key: const Key('guest-logout-anyway'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_GuestLogoutChoice.logOut),
              child: Text(dialogContext.l10n.logoutAnyway),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;

    switch (choice) {
      case _GuestLogoutChoice.secure:
        router.push(AppRoutes.accountUpgrade);
      case _GuestLogoutChoice.logOut:
        await homeCubit.signOutUser();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          // Forget the cached trophy count of the user who just left.
          if (state is HomeSignedOut) {
            context.read<BadgeSummaryCubit>().clear();
          }
        },
        child: AnimatedGameBackground(
          child: SafeArea(
            child: BlocBuilder<BadgeSummaryCubit, BadgeSummary?>(
              builder: (context, summary) => BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  final user = state is HomeLoaded ? state.userInfo : null;
                  return Column(
                    children: [
                      HomeTopBar(
                        userInfo: user,
                        summary: summary,
                        onProfile: () => _openProfile(user!, summary),
                        onTrophy: () => context.push(AppRoutes.stats),
                        onSettings: () => context.push(AppRoutes.settings),
                      ),
                      Expanded(
                        child: _buildBody(
                          context,
                          state,
                          summary,
                          isTablet,
                          size,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    HomeState state,
    BadgeSummary? summary,
    bool isTablet,
    Size size,
  ) {
    if (state is HomeLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state is HomeError) {
      return Center(
        child: Text(
          context.l10n.errorWithMessage(
            localizedErrorMessage(context.l10n, state.code),
          ),
          style: TextStyle(color: AppColors.error),
        ),
      );
    }

    if (state is HomeLoaded) {
      final user = state.userInfo;
      final showBanner =
          (user.isAnonymous || user.isLegacyAccount) &&
          summary != null &&
          summary.gamesPlayed > 0;
      final horizontal = isTablet ? size.width * 0.15 : 24.0;
      // Fill the screen: the banner sits under the top bar, the hero takes
      // the free space in the middle, and the buttons stay low within thumb
      // reach. On short screens (or large text) it scrolls instead.
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 40),
            ),
            child: IntrinsicHeight(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBanner)
                        GuestBanner(userId: user.id, store: widget.bannerStore),
                      // 3:2 keeps the hero a little closer to the buttons
                      // than to the top bar on tall phones.
                      const Spacer(flex: 3),
                      SizedBox(height: isTablet ? 24 : 16),
                      HomeHero(isTablet: isTablet),
                      SizedBox(height: isTablet ? 24 : 16),
                      const Spacer(flex: 2),
                      HomeActionButtons(isTablet: isTablet),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

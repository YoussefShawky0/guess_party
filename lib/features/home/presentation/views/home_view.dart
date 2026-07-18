import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/router/app_routes.dart';
import 'package:guess_party/core/services/update_service.dart';
import 'package:guess_party/core/di/injection_container.dart' as di;
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:guess_party/l10n/l10n.dart';

import 'widgets/home_action_buttons.dart';
import 'widgets/welcome_section.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<HomeCubit>()..loadUserInfo(),
      child: const HomeContent(),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  // Check for app updates using the UpdateService
  Future<void> _checkForUpdates() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(seconds: 2));

    final updateInfo = await UpdateService.checkForUpdate(di.sl<AppConfig>());

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
              UpdateService.startFlexibleUpdate(di.sl<AppConfig>());
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(context.l10n.update),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.of(context).surface,
                    AppColors.of(context).surface.withValues(alpha: 0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Logo
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/Front_Imposter_ingroup.png',
                        height: 28,
                        fit: BoxFit.contain,
                        cacheHeight: 78,
                        cacheWidth: 89,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      context.l10n.appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                  ),
                  // Settings Button
                  IconButton(
                    icon: const FaIcon(FontAwesomeIcons.gear, size: 18),
                    color: AppColors.of(context).textPrimary,
                    tooltip: context.l10n.settings,
                    onPressed: () {
                      context.push(AppRoutes.settings);
                    },
                  ),
                  // Logout Button
                  IconButton(
                    icon: const FaIcon(
                      FontAwesomeIcons.rightFromBracket,
                      size: 18,
                    ),
                    color: AppColors.error,
                    tooltip: context.l10n.logout,
                    onPressed: () {
                      context.read<HomeCubit>().signOutUser();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<HomeCubit, HomeState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is HomeLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    );
                  }

                  if (state is HomeError) {
                    return Center(
                      child: Text(
                        context.l10n.errorWithMessage(state.message),
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  }

                  if (state is HomeLoaded) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? size.width * 0.15 : 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              WelcomeSection(
                                username: state.userInfo.username,
                                isTablet: isTablet,
                              ),
                              if (state.userInfo.isAnonymous ||
                                  state.userInfo.isLegacyAccount) ...[
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  key: const Key('secure-account-button'),
                                  onPressed: () =>
                                      context.push(AppRoutes.accountUpgrade),
                                  icon: const Icon(
                                    Icons.mark_email_read_outlined,
                                  ),
                                  label: Text(
                                    state.userInfo.isAnonymous
                                        ? context.l10n.secureGuestAccount
                                        : context.l10n.linkRecoveryEmail,
                                  ),
                                ),
                              ],
                              SizedBox(height: isTablet ? 48 : 32),
                              HomeActionButtons(isTablet: isTablet),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

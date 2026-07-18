import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:guess_party/core/services/update_service.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/features/home/domain/usecases/delete_account.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:guess_party/l10n/l10n.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        title: Text(context.l10n.settings),
        backgroundColor: AppColors.of(context).surface,
        foregroundColor: AppColors.of(context).textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        children: [
          // How to Play Section
          _SettingsSection(
            icon: FontAwesomeIcons.circleQuestion,
            title: context.l10n.howToPlay,
            isTablet: isTablet,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.gamepad,
                title: context.l10n.gameRules,
                subtitle: context.l10n.learnHowToPlay,
                isTablet: isTablet,
                onTap: () {
                  _showHowToPlayDialog(context, isTablet);
                },
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Appearance Section
          BlocBuilder<ThemeCubit, ThemeMode>(
            bloc: sl<ThemeCubit>(),
            builder: (context, themeMode) {
              final themeName = switch (themeMode) {
                ThemeMode.dark => context.l10n.dark,
                ThemeMode.light => context.l10n.light,
                ThemeMode.system => context.l10n.systemDefault,
              };
              return _SettingsSection(
                icon: FontAwesomeIcons.paintbrush,
                title: context.l10n.appearance,
                isTablet: isTablet,
                children: [
                  _SettingsTile(
                    icon: FontAwesomeIcons.palette,
                    title: context.l10n.theme,
                    subtitle: themeName,
                    isTablet: isTablet,
                    onTap: () => _showThemePicker(context, themeMode, isTablet),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // Language Section
          BlocBuilder<LocaleCubit, Locale?>(
            bloc: sl<LocaleCubit>(),
            builder: (context, locale) {
              final languageName = switch (locale?.languageCode) {
                'en' => context.l10n.english,
                'ar' => context.l10n.arabic,
                _ => context.l10n.systemDefaultLanguage,
              };
              return _SettingsSection(
                icon: FontAwesomeIcons.language,
                title: context.l10n.language,
                isTablet: isTablet,
                children: [
                  _SettingsTile(
                    key: const Key('settings-language'),
                    icon: FontAwesomeIcons.language,
                    title: context.l10n.language,
                    subtitle: languageName,
                    isTablet: isTablet,
                    onTap: () => _showLanguagePicker(context, locale, isTablet),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isTablet ? 24 : 16),

          _SettingsSection(
            icon: FontAwesomeIcons.userShield,
            title: context.l10n.account,
            isTablet: isTablet,
            children: [
              _SettingsTile(
                key: const Key('settings-delete-account'),
                icon: FontAwesomeIcons.trashCan,
                title: context.l10n.deleteAccount,
                subtitle: context.l10n.deleteAccountSubtitle,
                isTablet: isTablet,
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // About Section
          _SettingsSection(
            icon: FontAwesomeIcons.circleInfo,
            title: context.l10n.about,
            isTablet: isTablet,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.mobileScreen,
                title: context.l10n.appVersion,
                subtitle: _appVersion,
                isTablet: isTablet,
                onTap: null,
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.code,
                title: context.l10n.developer,
                subtitle: 'Youssef Shawky',
                isTablet: isTablet,
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/YoussefShawky0'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              if (UpdateService.isSupported(sl<AppConfig>()))
                _SettingsTile(
                  icon: FontAwesomeIcons.download,
                  title: context.l10n.checkForUpdates,
                  subtitle: context.l10n.managedByGooglePlay,
                  isTablet: isTablet,
                  onTap: () {
                    _checkForUpdates(context);
                  },
                ),
              _SettingsTile(
                icon: FontAwesomeIcons.fileShield,
                title: context.l10n.privacyPolicy,
                subtitle: context.l10n.viewPrivacyPolicy,
                isTablet: isTablet,
                onTap: () {
                  launchUrl(
                    Uri.parse(
                      'https://youssefshawky0.github.io/guess-party-privacy/',
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    Locale? current,
    bool isTablet,
  ) {
    final options = <({Locale? locale, String label})>[
      (locale: null, label: context.l10n.systemDefaultLanguage),
      (locale: const Locale('en'), label: context.l10n.english),
      (locale: const Locale('ar'), label: context.l10n.arabic),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  context.l10n.chooseLanguage,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              ),
              ...options.map((option) {
                final selected =
                    option.locale?.languageCode == current?.languageCode ||
                    (option.locale == null && current == null);
                return InkWell(
                  onTap: () {
                    sl<LocaleCubit>().setLocale(option.locale);
                    Navigator.of(sheetContext).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(isTablet ? 16 : 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.of(context).cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.language,
                          size: isTablet ? 22 : 18,
                          color: selected
                              ? AppColors.primary
                              : AppColors.of(context).textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? AppColors.of(context).textPrimary
                                : AppColors.of(context).textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (selected)
                          FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: isTablet ? 20 : 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          context.l10n.deleteAccountTitle,
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: Text(
          context.l10n.deleteAccountMessage,
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.deleteAccount),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await sl<DeleteAccount>()();
    if (!context.mounted) return;
    Navigator.of(context).pop();

    result.fold(
      (failure) => _showDeleteError(context, failure.message),
      (_) {},
    );
  }

  void _showDeleteError(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        title: Text(
          context.l10n.deleteAccountFailed,
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: Text(
          context.l10n.errorWithMessage(message),
          style: TextStyle(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(
    BuildContext context,
    ThemeMode current,
    bool isTablet,
  ) {
    final options = [
      (ThemeMode.dark, FontAwesomeIcons.moon, context.l10n.dark),
      (ThemeMode.light, FontAwesomeIcons.sun, context.l10n.light),
      (
        ThemeMode.system,
        FontAwesomeIcons.circleHalfStroke,
        context.l10n.systemDefault,
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  context.l10n.chooseTheme,
                  style: TextStyle(
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.of(context).textPrimary,
                  ),
                ),
              ),
              ...options.map((opt) {
                final (mode, icon, label) = opt;
                final isSelected = mode == current;
                return InkWell(
                  onTap: () {
                    sl<ThemeCubit>().setTheme(mode);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(isTablet ? 16 : 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.of(context).cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        FaIcon(
                          icon,
                          size: isTablet ? 22 : 18,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.of(context).textSecondary,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.of(context).textPrimary
                                : AppColors.of(context).textSecondary,
                          ),
                        ),
                        if (mode == ThemeMode.light) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              context.l10n.demo,
                              style: TextStyle(
                                fontSize: isTablet ? 12 : 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (isSelected)
                          FaIcon(
                            FontAwesomeIcons.circleCheck,
                            size: isTablet ? 20 : 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          context.l10n.checkingForUpdates,
          style: TextStyle(color: AppColors.of(context).textPrimary),
        ),
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                context.l10n.pleaseWait,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
            ),
          ],
        ),
      ),
    );

    final updateInfo = await UpdateService.checkForUpdate(sl<AppConfig>());

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (updateInfo == null) {
      _showUpdateErrorDialog(context);
      return;
    }

    if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
      _showUpdateAvailableDialog(context, updateInfo);
      return;
    }

    _showUpToDateDialog(context);
  }

  void _showUpToDateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circleCheck,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.upToDate,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: Text(
          context.l10n.latestVersionMessage(_appVersion),
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.ok,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateAvailableDialog(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) {
    final canImmediate = updateInfo.immediateUpdateAllowed;
    final canFlexible = updateInfo.flexibleUpdateAllowed;

    if (!canImmediate && !canFlexible) {
      _showUpdateErrorDialog(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: AppColors.primary, size: 24),
            const SizedBox(width: 12),
            Text(
              context.l10n.updateAvailable,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: Text(
          context.l10n.playStoreUpdateMessage,
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
              if (canImmediate) {
                UpdateService.performImmediateUpdate(sl<AppConfig>());
              } else {
                UpdateService.startFlexibleUpdate(sl<AppConfig>());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text(
              canImmediate ? context.l10n.updateNow : context.l10n.update,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: AppColors.warning,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.updateCheckFailed,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: Text(
          context.l10n.updateCheckFailedMessage,
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.ok,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showHowToPlayDialog(BuildContext context, bool isTablet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.of(context).surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.gamepad,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              context.l10n.howToPlay,
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _HowToPlayStep(
                number: '1',
                title: context.l10n.chooseMode,
                description: context.l10n.chooseModeDescription,
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '2',
                title: context.l10n.createOrJoinRoom,
                description: context.l10n.createOrJoinRoomDescription,
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '3',
                title: context.l10n.getYourRole,
                description: context.l10n.getYourRoleDescription,
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '4',
                title: context.l10n.hintsAndVoting,
                description: context.l10n.hintsAndVotingDescription,
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '5',
                title: context.l10n.resultsAndScoring,
                description: context.l10n.resultsAndScoringDescription,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.l10n.gotIt,
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final List<Widget> children;
  final bool isTablet;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.children,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              FaIcon(icon, size: isTablet ? 20 : 18, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.of(context).surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final FaIconData icon;
  final String title;
  final String subtitle;
  final bool isTablet;
  final VoidCallback? onTap;

  const _SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isTablet,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  icon,
                  size: isTablet ? 24 : 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.of(context).textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.of(context).textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: isTablet ? 18 : 16,
                  color: AppColors.of(context).textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HowToPlayStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _HowToPlayStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.of(context).textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.of(context).textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

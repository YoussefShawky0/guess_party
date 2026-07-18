import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:guess_party/core/services/update_service.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/features/home/domain/usecases/delete_account.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/account_deletion_dialog.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/how_to_play_dialog.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/settings_picker_sheets.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/settings_section.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/settings_tile.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/update_dialogs.dart';
import 'package:guess_party/l10n/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  static final Uri _developerUri = Uri.parse(
    'https://github.com/YoussefShawky0',
  );
  static final Uri _privacyPolicyUri = Uri.parse(
    'https://youssefshawky0.github.io/guess-party-privacy/',
  );

  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).width > 600;
    final spacing = SizedBox(height: isTablet ? 24 : 16);

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
          _buildHowToPlaySection(context, isTablet),
          spacing,
          _buildAppearanceSection(isTablet),
          spacing,
          _buildLanguageSection(isTablet),
          spacing,
          _buildAccountSection(context, isTablet),
          spacing,
          _buildAboutSection(context, isTablet),
        ],
      ),
    );
  }

  Widget _buildHowToPlaySection(BuildContext context, bool isTablet) {
    return SettingsSection(
      icon: FontAwesomeIcons.circleQuestion,
      title: context.l10n.howToPlay,
      isTablet: isTablet,
      children: [
        SettingsTile(
          icon: FontAwesomeIcons.gamepad,
          title: context.l10n.gameRules,
          subtitle: context.l10n.learnHowToPlay,
          isTablet: isTablet,
          onTap: () => showHowToPlayDialog(context: context),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(bool isTablet) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: sl<ThemeCubit>(),
      builder: (context, themeMode) {
        final themeName = switch (themeMode) {
          ThemeMode.dark => context.l10n.dark,
          ThemeMode.light => context.l10n.light,
          ThemeMode.system => context.l10n.systemDefault,
        };
        return SettingsSection(
          icon: FontAwesomeIcons.paintbrush,
          title: context.l10n.appearance,
          isTablet: isTablet,
          children: [
            SettingsTile(
              icon: FontAwesomeIcons.palette,
              title: context.l10n.theme,
              subtitle: themeName,
              isTablet: isTablet,
              onTap: () => showThemePicker(
                context: context,
                current: themeMode,
                themeCubit: sl<ThemeCubit>(),
                isTablet: isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageSection(bool isTablet) {
    return BlocBuilder<LocaleCubit, Locale?>(
      bloc: sl<LocaleCubit>(),
      builder: (context, locale) {
        final languageName = switch (locale?.languageCode) {
          'en' => context.l10n.english,
          'ar' => context.l10n.arabic,
          _ => context.l10n.systemDefaultLanguage,
        };
        return SettingsSection(
          icon: FontAwesomeIcons.language,
          title: context.l10n.language,
          isTablet: isTablet,
          children: [
            SettingsTile(
              key: const Key('settings-language'),
              icon: FontAwesomeIcons.language,
              title: context.l10n.language,
              subtitle: languageName,
              isTablet: isTablet,
              onTap: () => showLanguagePicker(
                context: context,
                current: locale,
                localeCubit: sl<LocaleCubit>(),
                isTablet: isTablet,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(BuildContext context, bool isTablet) {
    return SettingsSection(
      icon: FontAwesomeIcons.userShield,
      title: context.l10n.account,
      isTablet: isTablet,
      children: [
        SettingsTile(
          key: const Key('settings-delete-account'),
          icon: FontAwesomeIcons.trashCan,
          title: context.l10n.deleteAccount,
          subtitle: context.l10n.deleteAccountSubtitle,
          isTablet: isTablet,
          onTap: () => confirmAccountDeletion(
            context: context,
            deleteAccount: () => sl<DeleteAccount>()(),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, bool isTablet) {
    final config = sl<AppConfig>();
    return SettingsSection(
      icon: FontAwesomeIcons.circleInfo,
      title: context.l10n.about,
      isTablet: isTablet,
      children: [
        SettingsTile(
          icon: FontAwesomeIcons.mobileScreen,
          title: context.l10n.appVersion,
          subtitle: _appVersion,
          isTablet: isTablet,
        ),
        SettingsTile(
          icon: FontAwesomeIcons.code,
          title: context.l10n.developer,
          subtitle: 'Youssef Shawky',
          isTablet: isTablet,
          onTap: () =>
              launchUrl(_developerUri, mode: LaunchMode.externalApplication),
        ),
        if (UpdateService.isSupported(config))
          SettingsTile(
            icon: FontAwesomeIcons.download,
            title: context.l10n.checkForUpdates,
            subtitle: context.l10n.managedByGooglePlay,
            isTablet: isTablet,
            onTap: () => checkForUpdates(
              context: context,
              config: config,
              appVersion: _appVersion,
            ),
          ),
        SettingsTile(
          icon: FontAwesomeIcons.fileShield,
          title: context.l10n.privacyPolicy,
          subtitle: context.l10n.viewPrivacyPolicy,
          isTablet: isTablet,
          onTap: () => launchUrl(
            _privacyPolicyUri,
            mode: LaunchMode.externalApplication,
          ),
        ),
      ],
    );
  }
}

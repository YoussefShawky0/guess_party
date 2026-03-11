import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
        title: const Text('Settings'),
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
            title: 'How to Play',
            isTablet: isTablet,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.gamepad,
                title: 'Game Rules',
                subtitle: 'Learn how to play Guess Party',
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
              final themeName = sl<ThemeCubit>().currentThemeName;
              return _SettingsSection(
                icon: FontAwesomeIcons.paintbrush,
                title: 'Appearance',
                isTablet: isTablet,
                children: [
                  _SettingsTile(
                    icon: FontAwesomeIcons.palette,
                    title: 'Theme',
                    subtitle: themeName,
                    isTablet: isTablet,
                    onTap: () => _showThemePicker(context, themeMode, isTablet),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: isTablet ? 24 : 16),

          // About Section
          _SettingsSection(
            icon: FontAwesomeIcons.circleInfo,
            title: 'About',
            isTablet: isTablet,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.mobileScreen,
                title: 'App Version',
                subtitle: _appVersion,
                isTablet: isTablet,
                onTap: null,
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.code,
                title: 'Developer',
                subtitle: 'Youssef Shawky',
                isTablet: isTablet,
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/YoussefShawky0'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.github,
                title: 'View on GitHub',
                subtitle: 'Check out the source code',
                isTablet: isTablet,
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/YoussefShawky0/guess_party'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.download,
                title: 'Check for Updates',
                subtitle: 'You\'re on the latest version',
                isTablet: isTablet,
                onTap: () {
                  _checkForUpdates(context);
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.fileShield,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                isTablet: isTablet,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Privacy policy coming soon!'),
                      backgroundColor: AppColors.primary,
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

  void _showThemePicker(
    BuildContext context,
    ThemeMode current,
    bool isTablet,
  ) {
    final options = [
      (ThemeMode.dark, FontAwesomeIcons.moon, 'Dark'),
      (ThemeMode.light, FontAwesomeIcons.sun, 'Light'),
      (ThemeMode.system, FontAwesomeIcons.circleHalfStroke, 'System Default'),
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
                  'Choose Theme',
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
                              'Demo',
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

  void _checkForUpdates(BuildContext context) {
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
              'Up to Date!',
              style: TextStyle(color: AppColors.of(context).textPrimary),
            ),
          ],
        ),
        content: Text(
          'You are running the latest version of Guess Party (0.1.0).',
          style: TextStyle(
            color: AppColors.of(context).textSecondary,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppColors.primary)),
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
              'How to Play',
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
                title: 'Create or Join Room',
                description:
                    'Start a new game or join an existing room with friends.',
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '2',
                title: 'Get Your Role',
                description:
                    'You\'ll be assigned as either an Innocent player or the Imposter.',
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '3',
                title: 'Hints Phase',
                description:
                    'Innocents give hints about the character. Imposter tries to blend in!',
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '4',
                title: 'Voting Phase',
                description: 'Vote for who you think is the Imposter.',
              ),
              const SizedBox(height: 12),
              _HowToPlayStep(
                number: '5',
                title: 'Results & Scoring',
                description:
                    'If Imposter is caught: voters get +10 points.\nIf Imposter escapes: Imposter gets +20 points.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
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
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isTablet;
  final VoidCallback? onTap;

  const _SettingsTile({
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

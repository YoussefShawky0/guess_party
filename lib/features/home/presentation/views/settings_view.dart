import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        children: [
          // Appearance Section
          _SettingsSection(
            icon: FontAwesomeIcons.paintbrush,
            title: 'Appearance',
            isTablet: isTablet,
            children: [
              _SettingsTile(
                icon: FontAwesomeIcons.palette,
                title: 'Theme',
                subtitle: 'Dark',
                isTablet: isTablet,
                onTap: () {
                  // TODO: Implement theme switcher
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Theme switching coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.textHeight,
                title: 'Font Size',
                subtitle: 'Medium',
                isTablet: isTablet,
                onTap: () {
                  // TODO: Implement font size selector
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Font size options coming soon!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
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
                subtitle: '0.1.0',
                isTablet: isTablet,
                onTap: null, // Not tappable
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.code,
                title: 'Developer',
                subtitle: 'Youssef Shawky',
                isTablet: isTablet,
                onTap: () async {
                  final uri = Uri.parse('https://github.com/YoussefShawky0');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.circleQuestion,
                title: 'How to Play',
                subtitle: 'Learn the game rules',
                isTablet: isTablet,
                onTap: () {
                  _showHowToPlayDialog(context, isTablet);
                },
              ),
              _SettingsTile(
                icon: FontAwesomeIcons.fileShield,
                title: 'Privacy Policy',
                subtitle: 'View our privacy policy',
                isTablet: isTablet,
                onTap: () {
                  // TODO: Add privacy policy
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
          SizedBox(height: isTablet ? 24 : 16),

          // Updates Section
          _SettingsSection(
            icon: FontAwesomeIcons.arrowsRotate,
            title: 'Updates',
            isTablet: isTablet,
            children: [
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
                icon: FontAwesomeIcons.github,
                title: 'View on GitHub',
                subtitle: 'Check out the source code',
                isTablet: isTablet,
                onTap: () async {
                  final uri = Uri.parse(
                    'https://github.com/YoussefShawky0/guess_party',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkForUpdates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.circleCheck,
              color: AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('Up to Date!', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'You are running the latest version of Guess Party (0.1.0).',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.gamepad,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('How to Play', style: TextStyle(color: AppColors.textPrimary)),
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
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
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
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: isTablet ? 18 : 16,
                  color: AppColors.textMuted,
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
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: AppColors.textSecondary,
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

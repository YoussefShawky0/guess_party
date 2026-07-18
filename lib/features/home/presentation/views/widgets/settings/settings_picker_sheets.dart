import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/localization/locale_cubit.dart';
import 'package:guess_party/core/theme/theme_cubit.dart';
import 'package:guess_party/l10n/l10n.dart';

Future<void> showLanguagePicker({
  required BuildContext context,
  required Locale? current,
  required LocaleCubit localeCubit,
  required bool isTablet,
}) {
  final options = <({Locale? locale, String label})>[
    (locale: null, label: context.l10n.systemDefaultLanguage),
    (locale: const Locale('en'), label: context.l10n.english),
    (locale: const Locale('ar'), label: context.l10n.arabic),
  ];

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SettingsPickerSheet<Locale?>(
      title: context.l10n.chooseLanguage,
      isTablet: isTablet,
      options: [
        for (final option in options)
          SettingsPickerOption(
            value: option.locale,
            label: option.label,
            icon: FontAwesomeIcons.language,
            selected:
                option.locale?.languageCode == current?.languageCode ||
                (option.locale == null && current == null),
          ),
      ],
      onSelected: (locale) {
        localeCubit.setLocale(locale);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

Future<void> showThemePicker({
  required BuildContext context,
  required ThemeMode current,
  required ThemeCubit themeCubit,
  required bool isTablet,
}) {
  final options = [
    SettingsPickerOption(
      value: ThemeMode.dark,
      label: context.l10n.dark,
      icon: FontAwesomeIcons.moon,
      selected: current == ThemeMode.dark,
    ),
    SettingsPickerOption(
      value: ThemeMode.light,
      label: context.l10n.light,
      icon: FontAwesomeIcons.sun,
      selected: current == ThemeMode.light,
      badge: context.l10n.demo,
    ),
    SettingsPickerOption(
      value: ThemeMode.system,
      label: context.l10n.systemDefault,
      icon: FontAwesomeIcons.circleHalfStroke,
      selected: current == ThemeMode.system,
    ),
  ];

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.of(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SettingsPickerSheet<ThemeMode>(
      title: context.l10n.chooseTheme,
      isTablet: isTablet,
      options: options,
      onSelected: (mode) {
        themeCubit.setTheme(mode);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class SettingsPickerOption<T> {
  const SettingsPickerOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    this.badge,
  });

  final T value;
  final String label;
  final FaIconData icon;
  final bool selected;
  final String? badge;
}

class _SettingsPickerSheet<T> extends StatelessWidget {
  const _SettingsPickerSheet({
    required this.title,
    required this.isTablet,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final bool isTablet;
  final List<SettingsPickerOption<T>> options;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
            ),
            for (final option in options)
              InkWell(
                onTap: () => onSelected(option.value),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(isTablet ? 16 : 14),
                  decoration: BoxDecoration(
                    color: option.selected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: option.selected
                          ? AppColors.primary
                          : AppColors.of(context).cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      FaIcon(
                        option.icon,
                        size: isTablet ? 22 : 18,
                        color: option.selected
                            ? AppColors.primary
                            : AppColors.of(context).textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        option.label,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: option.selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: option.selected
                              ? AppColors.of(context).textPrimary
                              : AppColors.of(context).textSecondary,
                        ),
                      ),
                      if (option.badge case final badge?) ...[
                        const SizedBox(width: 8),
                        _PickerBadge(label: badge, isTablet: isTablet),
                      ],
                      const Spacer(),
                      if (option.selected)
                        FaIcon(
                          FontAwesomeIcons.circleCheck,
                          size: isTablet ? 20 : 16,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PickerBadge extends StatelessWidget {
  const _PickerBadge({required this.label, required this.isTablet});

  final String label;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: isTablet ? 12 : 11,
          fontWeight: FontWeight.bold,
          color: AppColors.warning,
        ),
      ),
    );
  }
}

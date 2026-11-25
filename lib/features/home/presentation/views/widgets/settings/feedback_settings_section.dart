import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/features/game/presentation/feedback/game_feedback_listener.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/settings_section.dart';
import 'package:guess_party/features/home/presentation/views/widgets/settings/settings_tile.dart';
import 'package:guess_party/l10n/l10n.dart';

/// "Sound effects" and "Vibration" switches backed by [GameFeedback].
class FeedbackSettingsSection extends StatefulWidget {
  const FeedbackSettingsSection({required this.isTablet, super.key});

  final bool isTablet;

  @override
  State<FeedbackSettingsSection> createState() =>
      _FeedbackSettingsSectionState();
}

class _FeedbackSettingsSectionState extends State<FeedbackSettingsSection> {
  GameFeedback? _feedback;

  GameFeedback get _service => _feedback ??= gameFeedbackOf(context);

  void _setSound(bool value) => _apply(_service.setSoundEnabled(value));

  void _setHaptics(bool value) => _apply(_service.setHapticsEnabled(value));

  void _apply(Future<void> change) {
    setState(() {});
    change.whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return SettingsSection(
      icon: FontAwesomeIcons.volumeHigh,
      title: context.l10n.soundAndHaptics,
      isTablet: widget.isTablet,
      children: [
        SettingsTile(
          key: const Key('settings-sound'),
          icon: FontAwesomeIcons.music,
          title: context.l10n.soundEffects,
          subtitle: context.l10n.soundEffectsSubtitle,
          isTablet: widget.isTablet,
          onTap: () => _setSound(!service.soundEnabled),
          trailing: Switch(
            key: const Key('settings-sound-switch'),
            value: service.soundEnabled,
            onChanged: _setSound,
          ),
        ),
        SettingsTile(
          key: const Key('settings-vibration'),
          icon: FontAwesomeIcons.mobileScreenButton,
          title: context.l10n.vibration,
          subtitle: context.l10n.vibrationSubtitle,
          isTablet: widget.isTablet,
          onTap: () => _setHaptics(!service.hapticsEnabled),
          trailing: Switch(
            key: const Key('settings-vibration-switch'),
            value: service.hapticsEnabled,
            onChanged: _setHaptics,
          ),
        ),
      ],
    );
  }
}

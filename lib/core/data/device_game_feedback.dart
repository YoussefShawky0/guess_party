import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:guess_party/core/services/game_feedback.dart';

/// Platform seam for [DeviceGameFeedback] so tests never touch audioplayers
/// or the haptic channel.
abstract class CuePlayer {
  Future<void> preload();
  Future<void> playSound(GameCue cue);
  Future<void> vibrate(GameCue cue);
}

/// Real feedback: sound and haptics gated by two persisted toggles.
class DeviceGameFeedback implements GameFeedback {
  DeviceGameFeedback({
    required SharedPreferences preferences,
    required CuePlayer player,
  }) : _preferences = preferences,
       _player = player,
       _soundEnabled = preferences.getBool(soundKey) ?? true,
       _hapticsEnabled = preferences.getBool(hapticsKey) ?? true;

  static const soundKey = 'feedback.sound_enabled';
  static const hapticsKey = 'feedback.haptics_enabled';

  final SharedPreferences _preferences;
  final CuePlayer _player;
  bool _soundEnabled;
  bool _hapticsEnabled;

  @override
  bool get soundEnabled => _soundEnabled;

  @override
  bool get hapticsEnabled => _hapticsEnabled;

  /// Warms up the audio players. Never throws.
  Future<void> preload() => _guard('preload', _player.preload);

  @override
  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _guard('persistSound', () => _preferences.setBool(soundKey, value));
  }

  @override
  Future<void> setHapticsEnabled(bool value) async {
    _hapticsEnabled = value;
    await _guard(
      'persistHaptics',
      () => _preferences.setBool(hapticsKey, value),
    );
  }

  @override
  Future<void> play(GameCue cue) async {
    if (_soundEnabled) await _guard('sound', () => _player.playSound(cue));
    if (_hapticsEnabled) await _guard('haptic', () => _player.vibrate(cue));
  }

  Future<void> _guard(String step, Future<Object?> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      unawaited(
        Sentry.captureException(
          error,
          stackTrace: stackTrace,
          withScope: (scope) => scope.setTag('feedback_step', step),
        ),
      );
    }
  }
}

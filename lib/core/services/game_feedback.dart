/// Moments in a game that deserve a short sound plus a vibration.
enum GameCue {
  tick,
  phaseStart,
  voteCast,
  imposterCaught,
  imposterEscaped,
  gameWon,
  gameLost,
}

/// Plays sound and haptic cues. Implementations must never throw from
/// [play]: feedback is decoration and may not affect gameplay.
abstract class GameFeedback {
  bool get soundEnabled;
  bool get hapticsEnabled;

  Future<void> setSoundEnabled(bool value);
  Future<void> setHapticsEnabled(bool value);

  Future<void> play(GameCue cue);

  /// A light haptic for a UI tap. No sound. Respects [hapticsEnabled] and
  /// never throws.
  Future<void> tapHaptic();
}

/// No-op feedback used by tests, CI and as the fallback when the platform
/// pieces are unavailable. Toggles are kept in memory only.
class SilentGameFeedback implements GameFeedback {
  SilentGameFeedback({bool soundEnabled = true, bool hapticsEnabled = true})
    : _soundEnabled = soundEnabled,
      _hapticsEnabled = hapticsEnabled;

  bool _soundEnabled;
  bool _hapticsEnabled;

  @override
  bool get soundEnabled => _soundEnabled;

  @override
  bool get hapticsEnabled => _hapticsEnabled;

  @override
  Future<void> setSoundEnabled(bool value) async => _soundEnabled = value;

  @override
  Future<void> setHapticsEnabled(bool value) async => _hapticsEnabled = value;

  @override
  Future<void> play(GameCue cue) async {}

  @override
  Future<void> tapHaptic() async {}
}

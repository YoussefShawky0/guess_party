/// Full-screen ad shown at a natural break: after a finished game, when the
/// player leaves the Game Over screen. Never shown mid-game, so it cannot
/// interrupt online state or a shared-device round.
abstract class InterstitialAdService {
  /// Gathers ad consent (UMP) and starts the ads SDK. Safe to call once at
  /// startup without awaiting; never throws.
  Future<void> initialize();

  /// Starts loading an ad so it is ready when the game ends.
  void preload();

  /// Shows a loaded ad if [AdFrequencyPolicy] allows it. Completes when the
  /// ad is dismissed, or immediately when nothing is shown. Never throws.
  Future<void> showAfterGameIfReady();
}

/// Used when ads are off (no unit configured, unsupported platform, tests).
class DisabledInterstitialAdService implements InterstitialAdService {
  const DisabledInterstitialAdService();

  @override
  Future<void> initialize() async {}

  @override
  void preload() {}

  @override
  Future<void> showAfterGameIfReady() async {}
}

/// Decides whether a finished game should end with an ad.
class AdFrequencyPolicy {
  const AdFrequencyPolicy();

  /// [lastShownAt] is null before the first ad this app session.
  /// [gamesSinceLastAd] counts finished games since the last shown ad,
  /// including the game that just ended (so it is at least 1).
  bool shouldShow({
    required DateTime now,
    required DateTime? lastShownAt,
    required int gamesSinceLastAd,
  }) {
    // Product decision (2026-11-24): one ad after every finished game. The
    // ad only appears at this natural break (leaving Game Over), never
    // mid-game. To space ads out later, use gamesSinceLastAd / lastShownAt.
    return true;
  }
}

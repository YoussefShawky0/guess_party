class ReconnectNoticeGate {
  ReconnectNoticeGate({
    this.cooldown = const Duration(seconds: 6),
    this.minimumCycle = const Duration(seconds: 1),
  });

  final Duration cooldown;
  final Duration minimumCycle;

  bool _cycleActive = false;
  bool _shownForCycle = false;
  DateTime? _cycleStartedAt;
  DateTime? _lastShownAt;

  void startCycle(DateTime now) {
    _cycleActive = true;
    _shownForCycle = false;
    _cycleStartedAt = now;
  }

  bool shouldShowBackOnline(DateTime now) {
    final duration = _cycleStartedAt == null
        ? Duration.zero
        : now.difference(_cycleStartedAt!);
    final withinCooldown =
        _lastShownAt != null && now.difference(_lastShownAt!) < cooldown;

    if (!_cycleActive ||
        _shownForCycle ||
        duration < minimumCycle ||
        withinCooldown) {
      _cycleActive = false;
      return false;
    }

    _cycleActive = false;
    _shownForCycle = true;
    _lastShownAt = now;
    return true;
  }
}

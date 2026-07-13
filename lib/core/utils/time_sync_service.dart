import 'dart:developer' as developer;

import 'package:guess_party/core/services/server_clock.dart';

/// Handles time synchronization with Supabase server
/// to ensure consistent timing across all devices in online mode
class TimeSyncService {
  final ServerClock clock;

  TimeSyncService(this.clock);

  Duration? _timeOffset;
  DateTime? _lastSyncTime;
  bool _syncFailed = false;

  /// Whether the service has successfully synced at least once
  bool get hasSynced => _lastSyncTime != null && !_syncFailed;

  /// Whether the last sync attempt failed (using local time as fallback)
  bool get syncFailed => _syncFailed;

  /// Get the current server time (synchronized)
  /// Falls back to local time if sync hasn't happened yet
  DateTime get serverTime {
    if (_timeOffset == null) {
      return DateTime.now().toUtc();
    }
    return DateTime.now().toUtc().add(_timeOffset!);
  }

  /// Sync time with Supabase server with retry logic.
  /// Retries up to [maxRetries] times with progressive delay on failure.
  /// Returns true if sync succeeded, false if all attempts failed.
  Future<bool> syncWithServer({int maxRetries = 3}) async {
    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final beforeLocal = DateTime.now().toUtc();

        // Query server time
        final serverTime = await clock.getServerTime();
        final afterLocal = DateTime.now().toUtc();

        // Calculate average local time during the request
        final avgLocal = beforeLocal.add(
          Duration(
            milliseconds:
                afterLocal.difference(beforeLocal).inMilliseconds ~/ 2,
          ),
        );

        // Calculate offset: server time - local time
        _timeOffset = serverTime.difference(avgLocal);
        _lastSyncTime = DateTime.now().toUtc();
        _syncFailed = false;

        developer.log(
          'TimeSyncService: synced on attempt $attempt, '
          'offset=${_timeOffset!.inMilliseconds}ms',
          name: 'TimeSyncService',
        );
        return true;
      } catch (e) {
        developer.log(
          'TimeSyncService: attempt $attempt/$maxRetries failed: $e',
          name: 'TimeSyncService',
          level: 900, // WARNING level
        );
        if (attempt < maxRetries) {
          // Progressive delay: 1s, 2s, 3s...
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      }
    }

    // All retries exhausted — fall back to local time
    _timeOffset = Duration.zero;
    _syncFailed = true;
    developer.log(
      'TimeSyncService: all $maxRetries attempts failed, '
      'falling back to local time',
      name: 'TimeSyncService',
      level: 1000, // SEVERE level
    );
    return false;
  }

  /// Check if we need to resync (every 5 minutes)
  bool get needsResync {
    if (_lastSyncTime == null) return true;
    final now = DateTime.now().toUtc();
    return now.difference(_lastSyncTime!).inMinutes >= 5;
  }

  /// Reset sync (useful for testing or when switching games)
  void reset() {
    _timeOffset = null;
    _lastSyncTime = null;
    _syncFailed = false;
  }
}

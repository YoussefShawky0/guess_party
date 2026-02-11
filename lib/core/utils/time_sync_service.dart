import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles time synchronization with Supabase server
/// to ensure consistent timing across all devices in online mode
class TimeSyncService {
  static TimeSyncService? _instance;
  static TimeSyncService get instance => _instance ??= TimeSyncService._();
  
  TimeSyncService._();

  Duration? _timeOffset;
  DateTime? _lastSyncTime;
  
  /// Get the current server time (synchronized)
  /// Falls back to local time if sync hasn't happened yet
  DateTime get serverTime {
    if (_timeOffset == null) {
      return DateTime.now().toUtc();
    }
    return DateTime.now().toUtc().add(_timeOffset!);
  }

  /// Sync time with Supabase server
  /// Should be called when game starts or periodically
  Future<void> syncWithServer() async {
    try {
      final beforeLocal = DateTime.now().toUtc();
      
      // Query server time
      final response = await Supabase.instance.client
          .rpc('get_server_time')
          .select()
          .single();
      
      final afterLocal = DateTime.now().toUtc();
      final serverTimeStr = response['server_time'] as String;
      final serverTime = DateTime.parse(serverTimeStr).toUtc();
      
      // Calculate average local time during the request
      final avgLocal = beforeLocal.add(
        Duration(milliseconds: afterLocal.difference(beforeLocal).inMilliseconds ~/ 2),
      );
      
      // Calculate offset: server time - local time
      _timeOffset = serverTime.difference(avgLocal);
      _lastSyncTime = DateTime.now().toUtc();
      
    } catch (e) {
      // If sync fails, use local time (offset = 0)
      _timeOffset = Duration.zero;
    }
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
  }
}

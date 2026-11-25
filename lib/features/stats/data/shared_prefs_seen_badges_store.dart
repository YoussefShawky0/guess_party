import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/domain/seen_badges_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsSeenBadgesStore implements SeenBadgesStore {
  static const key = 'stats.seen_badges';

  @override
  Future<Set<BadgeId>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final names = prefs.getStringList(key) ?? const <String>[];
    return {
      for (final id in BadgeId.values)
        if (names.contains(id.name)) id,
    };
  }

  @override
  Future<void> write(Set<BadgeId> seen) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, [for (final id in seen) id.name]);
  }
}

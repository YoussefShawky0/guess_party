import 'dart:convert';

import 'package:guess_party/features/stats/domain/badge_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [BadgeSummaryStore] and [GuestBannerStore] on `SharedPreferences`.
/// Every key includes the user id, so accounts never see each other's data.
class SharedPrefsBadgeSummaryStore
    implements BadgeSummaryStore, GuestBannerStore {
  const SharedPrefsBadgeSummaryStore();

  static String summaryKey(String userId) => 'stats.summary.$userId';
  static String bannerKey(String userId) =>
      'home.guest_banner_dismissed.$userId';

  @override
  Future<BadgeSummary?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(summaryKey(userId));
    if (raw == null) return null;
    try {
      return BadgeSummary.tryFromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String userId, BadgeSummary summary) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(summaryKey(userId), jsonEncode(summary.toJson()));
  }

  @override
  Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(summaryKey(userId));
  }

  @override
  Future<bool> isDismissed(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(bannerKey(userId)) ?? false;
  }

  @override
  Future<void> dismiss(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(bannerKey(userId), true);
  }
}

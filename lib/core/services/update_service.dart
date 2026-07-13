import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<AppUpdateInfo?> checkForUpdate() async {
    if (!isSupported) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      return null;
    }
  }

  static Future<void> performImmediateUpdate() async {
    if (!isSupported) return;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> startFlexibleUpdate() async {
    if (!isSupported) return;
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      // Handle error silently
    }
  }
}

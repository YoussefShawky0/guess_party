import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';
import 'package:guess_party/core/config/app_config.dart';

class UpdateService {
  static bool isSupported(AppConfig config) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      config.environment == AppEnvironment.production &&
      config.distribution == AppDistribution.play;

  static Future<AppUpdateInfo?> checkForUpdate(AppConfig config) async {
    if (!isSupported(config)) return null;
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      return null;
    }
  }

  static Future<void> performImmediateUpdate(AppConfig config) async {
    if (!isSupported(config)) return;
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> startFlexibleUpdate(AppConfig config) async {
    if (!isSupported(config)) return;
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      // Handle error silently
    }
  }
}

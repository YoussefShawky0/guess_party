import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  static Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      return await InAppUpdate.checkForUpdate();
    } catch (e) {
      return null;
    }
  }

  static Future<void> performImmediateUpdate() async {
    try {
      await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      // Handle error silently
    }
  }

  static Future<void> startFlexibleUpdate() async {
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      // Handle error silently
    }
  }
}

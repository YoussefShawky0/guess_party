import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/config/app_config.dart';
import 'package:guess_party/core/services/update_service.dart';

void main() {
  final originalPlatform = debugDefaultTargetPlatformOverride;

  tearDown(() {
    debugDefaultTargetPlatformOverride = originalPlatform;
  });

  test('Play updates are enabled only for production Android builds', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final playConfig = _config(
      environment: 'production',
      distribution: 'play',
      release: 'test-release',
      dist: '1',
    );
    final internalConfig = _config(
      environment: 'production',
      distribution: 'appstore',
      release: 'test-release',
      dist: '1',
    );

    expect(UpdateService.isSupported(playConfig), isTrue);
    expect(UpdateService.isSupported(internalConfig), isFalse);
  });

  test('Play updates are disabled on iOS and development Android', () {
    final playConfig = _config(
      environment: 'production',
      distribution: 'play',
      release: 'test-release',
      dist: '1',
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(UpdateService.isSupported(playConfig), isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final development = _config(
      environment: 'development',
      distribution: 'internal',
    );
    expect(UpdateService.isSupported(development), isFalse);
  });
}

AppConfig _config({
  required String environment,
  required String distribution,
  String? release,
  String? dist,
}) {
  return AppConfig.fromMap({
    'APP_ENVIRONMENT': environment,
    'APP_DISTRIBUTION': distribution,
    'SUPABASE_URL': 'https://example.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    if (release != null) 'SENTRY_RELEASE': release,
    if (dist != null) 'SENTRY_DIST': dist,
    'SENTRY_TRACES_SAMPLE_RATE': '0.0',
  });
}

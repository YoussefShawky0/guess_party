import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/config/app_config.dart';

Map<String, String> _base({String environment = 'development'}) => {
  'APP_ENVIRONMENT': environment,
  'APP_DISTRIBUTION': environment == 'development' ? 'local' : 'internal',
  'SUPABASE_URL': environment == 'development'
      ? 'http://127.0.0.1:54321'
      : 'https://staging-project.supabase.co',
  'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
  if (environment != 'development') 'SENTRY_RELEASE': 'r',
  if (environment != 'development') 'SENTRY_DIST': 'd',
};

const _firebase = {
  'FIREBASE_API_KEY': 'k',
  'FIREBASE_APP_ID': 'a',
  'FIREBASE_PROJECT_ID': 'p',
  'FIREBASE_MESSAGING_SENDER_ID': 's',
};

void main() {
  group('Firebase config', () {
    test('is optional and off by default', () {
      final config = AppConfig.fromMap(_base());
      expect(config.hasFirebase, isFalse);
      expect(config.analyticsDebug, isFalse);
    });

    test('hasFirebase needs all four values', () {
      expect(AppConfig.fromMap({..._base(), ..._firebase}).hasFirebase, isTrue);
      for (final missing in _firebase.keys) {
        final partial = {..._firebase}..remove(missing);
        expect(
          AppConfig.fromMap({..._base(), ...partial}).hasFirebase,
          isFalse,
          reason: missing,
        );
      }
    });

    test('blank values count as missing', () {
      final config = AppConfig.fromMap({
        ..._base(),
        ..._firebase,
        'FIREBASE_APP_ID': '   ',
      });
      expect(config.hasFirebase, isFalse);
    });

    test('development collects analytics only with ANALYTICS_DEBUG=true', () {
      expect(AppConfig.fromMap(_base()).analyticsCollectionEnabled, isFalse);
      expect(
        AppConfig.fromMap({
          ..._base(),
          'ANALYTICS_DEBUG': 'true',
        }).analyticsCollectionEnabled,
        isTrue,
      );
      expect(
        AppConfig.fromMap({
          ..._base(),
          'ANALYTICS_DEBUG': 'nope',
        }).analyticsCollectionEnabled,
        isFalse,
      );
    });

    test('staging collects analytics by default', () {
      expect(
        AppConfig.fromMap(
          _base(environment: 'staging'),
        ).analyticsCollectionEnabled,
        isTrue,
      );
    });
  });
}

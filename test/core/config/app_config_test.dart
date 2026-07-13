import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('loads publishable client configuration', () {
      final config = AppConfig.fromMap({
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        'SENTRY_DSN': '',
      });

      expect(config.supabaseUrl, 'https://example.supabase.co');
      expect(config.supabasePublishableKey, 'sb_publishable_test');
      expect(config.sentryDsn, isNull);
      expect(config.environment, 'development');
      expect(config.sentryTracesSampleRate, 0.1);
    });

    test('loads observability environment and clamps sample rate', () {
      final config = AppConfig.fromMap({
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        'APP_ENVIRONMENT': 'STAGING',
        'SENTRY_TRACES_SAMPLE_RATE': '2.0',
      });

      expect(config.environment, 'staging');
      expect(config.sentryTracesSampleRate, 1.0);
    });

    test('supports the legacy anon key during migration', () {
      final config = AppConfig.fromMap({
        'SUPABASE_URL': 'https://example.supabase.co',
        'SUPABASE_ANON_KEY': 'legacy-anon-key',
      });

      expect(config.supabasePublishableKey, 'legacy-anon-key');
    });

    test('rejects a missing URL', () {
      expect(
        () => AppConfig.fromMap({
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects an invalid URL', () {
      expect(
        () => AppConfig.fromMap({
          'SUPABASE_URL': 'not-a-url',
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects a missing publishable key', () {
      expect(
        () => AppConfig.fromMap({
          'SUPABASE_URL': 'https://example.supabase.co',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}

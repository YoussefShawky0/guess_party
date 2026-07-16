import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/config/app_config.dart';

Map<String, String> _baseConfig({
  String environment = 'development',
  String distribution = 'local',
  String url = 'http://127.0.0.1:54321',
  String key = 'sb_publishable_test',
  String? sentryDsn,
  String? sampleRate,
  String? release,
  String? dist,
}) => {
  'APP_ENVIRONMENT': environment,
  'APP_DISTRIBUTION': distribution,
  'SUPABASE_URL': url,
  'SUPABASE_PUBLISHABLE_KEY': key,
  if (sentryDsn != null) 'SENTRY_DSN': sentryDsn,
  if (sampleRate != null) 'SENTRY_TRACES_SAMPLE_RATE': sampleRate,
  if (release != null) 'SENTRY_RELEASE': release,
  if (dist != null) 'SENTRY_DIST': dist,
};

void main() {
  group('AppConfig', () {
    test('loads local development publishable client configuration', () {
      final config = AppConfig.fromMap(_baseConfig());

      expect(config.environment, AppEnvironment.development);
      expect(config.distribution, AppDistribution.local);
      expect(config.supabaseUrl, 'http://127.0.0.1:54321');
      expect(config.supabasePublishableKey, 'sb_publishable_test');
      expect(config.sentryDsn, isNull);
      expect(config.isSentryEnabled, isFalse);
      expect(config.sentryTracesSampleRate, 0.1);
    });

    test('loads staging release metadata and clamps sample rate', () {
      final config = AppConfig.fromMap(
        _baseConfig(
          environment: 'STAGING',
          distribution: 'INTERNAL',
          url: 'https://staging-project.supabase.co',
          sentryDsn: 'https://public@example.ingest.sentry.io/1',
          sampleRate: '2.0',
          release: 'guess-party@1.0.0+42',
          dist: '42',
        ),
      );

      expect(config.environment, AppEnvironment.staging);
      expect(config.distribution, AppDistribution.internal);
      expect(config.sentryDsn, 'https://public@example.ingest.sentry.io/1');
      expect(config.isSentryEnabled, isTrue);
      expect(config.sentryTracesSampleRate, 1.0);
      expect(config.sentryRelease, 'guess-party@1.0.0+42');
      expect(config.sentryDist, '42');
    });

    test(
      'allows production only with store distribution and release metadata',
      () {
        final config = AppConfig.fromMap(
          _baseConfig(
            environment: 'production',
            distribution: 'play',
            url: 'https://prod-project.supabase.co',
            release: 'guess-party@1.0.0+99',
            dist: '99',
          ),
        );

        expect(config.environment, AppEnvironment.production);
        expect(config.distribution, AppDistribution.play);
      },
    );

    test('rejects missing required define values', () {
      expect(
        () => AppConfig.fromMap({
          'APP_ENVIRONMENT': 'development',
          'APP_DISTRIBUTION': 'local',
          'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects an invalid Supabase URL', () {
      expect(
        () => AppConfig.fromMap(_baseConfig(url: 'not-a-url')),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects a missing publishable key', () {
      expect(
        () => AppConfig.fromMap({
          'APP_ENVIRONMENT': 'development',
          'APP_DISTRIBUTION': 'local',
          'SUPABASE_URL': 'http://127.0.0.1:54321',
        }),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects obvious secret or service-role key markers', () {
      for (final key in [
        'sb_secret_not_for_clients',
        'service_role_key',
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake',
      ]) {
        expect(
          () => AppConfig.fromMap(_baseConfig(key: key)),
          throwsA(isA<AppConfigException>()),
        );
      }
    });

    test('rejects production builds pointed at non-production endpoints', () {
      for (final url in [
        'http://127.0.0.1:54321',
        'https://staging-project.supabase.co',
        'https://dev-project.supabase.co',
        'https://guess-party.local',
      ]) {
        expect(
          () => AppConfig.fromMap(
            _baseConfig(
              environment: 'production',
              distribution: 'play',
              url: url,
              release: 'guess-party@1.0.0+99',
              dist: '99',
            ),
          ),
          throwsA(isA<AppConfigException>()),
        );
      }
    });

    test('rejects incompatible environment and distribution combinations', () {
      expect(
        () => AppConfig.fromMap(
          _baseConfig(environment: 'development', distribution: 'play'),
        ),
        throwsA(isA<AppConfigException>()),
      );
      expect(
        () => AppConfig.fromMap(
          _baseConfig(
            environment: 'production',
            distribution: 'internal',
            url: 'https://prod-project.supabase.co',
            release: 'guess-party@1.0.0+99',
            dist: '99',
          ),
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('requires release and dist metadata outside development', () {
      expect(
        () => AppConfig.fromMap(
          _baseConfig(
            environment: 'staging',
            distribution: 'internal',
            url: 'https://staging-project.supabase.co',
          ),
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}

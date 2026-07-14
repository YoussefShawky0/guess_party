enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment parse(String value) {
    final normalized = value.trim().toLowerCase();
    return AppEnvironment.values.firstWhere(
      (environment) => environment.name == normalized,
      orElse: () => throw AppConfigException(
        'APP_ENVIRONMENT must be development, staging, or production.',
      ),
    );
  }
}

enum AppDistribution {
  local,
  internal,
  play,
  appstore;

  static AppDistribution parse(String value) {
    final normalized = value.trim().toLowerCase();
    return AppDistribution.values.firstWhere(
      (distribution) => distribution.name == normalized,
      orElse: () => throw AppConfigException(
        'APP_DISTRIBUTION must be local, internal, play, or appstore.',
      ),
    );
  }
}

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.distribution,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.sentryDsn,
    required this.sentryTracesSampleRate,
    required this.sentryRelease,
    required this.sentryDist,
  });

  final AppEnvironment environment;
  final AppDistribution distribution;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String? sentryDsn;
  final double sentryTracesSampleRate;
  final String? sentryRelease;
  final String? sentryDist;

  bool get isSentryEnabled => sentryDsn != null;

  static AppConfig fromEnvironment() => fromCompileTime();

  static AppConfig fromCompileTime() => fromMap(const {
    'APP_ENVIRONMENT': String.fromEnvironment('APP_ENVIRONMENT'),
    'APP_DISTRIBUTION': String.fromEnvironment('APP_DISTRIBUTION'),
    'SUPABASE_URL': String.fromEnvironment('SUPABASE_URL'),
    'SUPABASE_PUBLISHABLE_KEY': String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    'SENTRY_DSN': String.fromEnvironment('SENTRY_DSN'),
    'SENTRY_TRACES_SAMPLE_RATE': String.fromEnvironment(
      'SENTRY_TRACES_SAMPLE_RATE',
    ),
    'SENTRY_RELEASE': String.fromEnvironment('SENTRY_RELEASE'),
    'SENTRY_DIST': String.fromEnvironment('SENTRY_DIST'),
  });

  static AppConfig fromMap(Map<String, String> values) {
    final environmentValue = _required(values, 'APP_ENVIRONMENT');
    final distributionValue = _required(values, 'APP_DISTRIBUTION');
    final url = _required(values, 'SUPABASE_URL');
    final publishableKey = _required(values, 'SUPABASE_PUBLISHABLE_KEY');

    final appEnvironment = AppEnvironment.parse(environmentValue);
    final appDistribution = AppDistribution.parse(distributionValue);
    final uri = _parseSupabaseUri(url);
    _validatePublishableKey(publishableKey);
    _validateEnvironmentEndpoint(appEnvironment, appDistribution, uri);

    final sentryDsn = _optional(values, 'SENTRY_DSN');
    final sentryRelease = _optional(values, 'SENTRY_RELEASE');
    final sentryDist = _optional(values, 'SENTRY_DIST');
    final parsedSampleRate = double.tryParse(
      _optional(values, 'SENTRY_TRACES_SAMPLE_RATE') ?? '',
    );
    final sampleRate = (parsedSampleRate ?? 0.1).clamp(0.0, 1.0);

    if (appEnvironment != AppEnvironment.development) {
      if (sentryRelease == null) {
        throw const AppConfigException(
          'SENTRY_RELEASE is required for staging and production builds.',
        );
      }
      if (sentryDist == null) {
        throw const AppConfigException(
          'SENTRY_DIST is required for staging and production builds.',
        );
      }
    }

    return AppConfig(
      environment: appEnvironment,
      distribution: appDistribution,
      supabaseUrl: url.trim(),
      supabasePublishableKey: publishableKey.trim(),
      sentryDsn: sentryDsn,
      sentryTracesSampleRate: sampleRate,
      sentryRelease: sentryRelease,
      sentryDist: sentryDist,
    );
  }

  static String _required(Map<String, String> values, String key) {
    final value = values[key]?.trim();
    if (value == null || value.isEmpty) {
      throw AppConfigException('$key is not configured.');
    }
    return value;
  }

  static String? _optional(Map<String, String> values, String key) {
    final value = values[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  static Uri _parseSupabaseUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const AppConfigException('SUPABASE_URL is not a valid URL.');
    }
    return uri;
  }

  static void _validatePublishableKey(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('sb_secret_') ||
        normalized.contains('service_role') ||
        normalized.startsWith('eyj')) {
      throw const AppConfigException(
        'SUPABASE_PUBLISHABLE_KEY must be a publishable client key.',
      );
    }
  }

  static void _validateEnvironmentEndpoint(
    AppEnvironment environment,
    AppDistribution distribution,
    Uri uri,
  ) {
    final host = uri.host.toLowerCase();
    final isLoopback =
        host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host.startsWith('10.0.2.');
    final isLocalHost = isLoopback || host.endsWith('.local');

    if (environment == AppEnvironment.development) {
      if (distribution == AppDistribution.play ||
          distribution == AppDistribution.appstore) {
        throw const AppConfigException(
          'Development builds cannot use store distributions.',
        );
      }
      if (uri.scheme != 'https' && !(uri.scheme == 'http' && isLocalHost)) {
        throw const AppConfigException(
          'Development SUPABASE_URL must use HTTPS or local loopback HTTP.',
        );
      }
      return;
    }

    if (uri.scheme != 'https') {
      throw const AppConfigException(
        'Staging and production SUPABASE_URL values must use HTTPS.',
      );
    }
    if (distribution == AppDistribution.local) {
      throw const AppConfigException(
        'Staging and production builds cannot use the local distribution.',
      );
    }

    if (environment == AppEnvironment.production) {
      if (distribution == AppDistribution.internal) {
        throw const AppConfigException(
          'Production builds cannot use the internal distribution.',
        );
      }
      if (isLocalHost ||
          host.contains('localhost') ||
          host.contains('development') ||
          host.contains('dev') ||
          host.contains('staging')) {
        throw const AppConfigException(
          'Production SUPABASE_URL must point to the production project.',
        );
      }
    }
  }
}

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.sentryDsn,
    required this.environment,
    required this.sentryTracesSampleRate,
  });

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String? sentryDsn;
  final String environment;
  final double sentryTracesSampleRate;

  static AppConfig fromEnvironment() => fromMap(dotenv.env);

  static AppConfig fromMap(Map<String, String> environment) {
    final url = environment['SUPABASE_URL']?.trim() ?? '';
    final publishableKey =
        environment['SUPABASE_PUBLISHABLE_KEY']?.trim() ??
        environment['SUPABASE_ANON_KEY']?.trim() ??
        '';

    if (url.isEmpty) {
      throw const AppConfigException('SUPABASE_URL is not configured.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw const AppConfigException('SUPABASE_URL is not a valid URL.');
    }
    if (publishableKey.isEmpty) {
      throw const AppConfigException(
        'SUPABASE_PUBLISHABLE_KEY is not configured.',
      );
    }

    final sentryDsn = environment['SENTRY_DSN']?.trim();
    final appEnvironment = environment['APP_ENVIRONMENT']?.trim().toLowerCase();
    final parsedSampleRate = double.tryParse(
      environment['SENTRY_TRACES_SAMPLE_RATE']?.trim() ?? '',
    );
    final sampleRate = (parsedSampleRate ?? 0.1).clamp(0.0, 1.0);
    return AppConfig(
      supabaseUrl: url,
      supabasePublishableKey: publishableKey,
      sentryDsn: sentryDsn == null || sentryDsn.isEmpty ? null : sentryDsn,
      environment: appEnvironment == null || appEnvironment.isEmpty
          ? 'development'
          : appEnvironment,
      sentryTracesSampleRate: sampleRate,
    );
  }
}

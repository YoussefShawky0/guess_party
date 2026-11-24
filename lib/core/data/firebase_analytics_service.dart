import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Sends events to Firebase Analytics. Never throws; failures only leave a
/// Sentry breadcrumb.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  Future<void> setCollectionEnabled(bool enabled) async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
    } catch (error) {
      _breadcrumb('setCollectionEnabled', error);
    }
  }

  @override
  Future<void> log(AnalyticsEvent event) async {
    try {
      await _analytics.logEvent(name: event.name, parameters: event.params);
    } catch (error) {
      _breadcrumb(event.name, error);
    }
  }

  void _breadcrumb(String what, Object error) {
    try {
      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'analytics',
            message: 'analytics:$what failed',
            level: SentryLevel.warning,
            data: {'error': error.runtimeType.toString()},
          ),
        ),
      );
    } catch (_) {}
  }
}

import 'package:guess_party/core/services/analytics_service.dart';

class RecordingAnalytics implements AnalyticsService {
  final List<AnalyticsEvent> events = [];

  List<String> get names => [for (final event in events) event.name];

  @override
  Future<void> log(AnalyticsEvent event) async {
    events.add(event);
  }
}

/// Throws synchronously and asynchronously to prove callers are protected.
class ThrowingAnalytics implements AnalyticsService {
  @override
  Future<void> log(AnalyticsEvent event) => throw StateError('boom');
}

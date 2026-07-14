// ignore_for_file: deprecated_member_use

import 'package:sentry_flutter/sentry_flutter.dart';

class TelemetryScrubber {
  static const redacted = '[redacted]';

  static final List<RegExp> _sensitiveKeyPatterns = [
    RegExp('password', caseSensitive: false),
    RegExp('token', caseSensitive: false),
    RegExp('authorization', caseSensitive: false),
    RegExp('cookie', caseSensitive: false),
    RegExp('secret', caseSensitive: false),
    RegExp('service_role', caseSensitive: false),
    RegExp('character_id', caseSensitive: false),
    RegExp('imposter_player_id', caseSensitive: false),
    RegExp(r'(^|_)role($|_)', caseSensitive: false),
    RegExp('chat', caseSensitive: false),
    RegExp('content', caseSensitive: false),
    RegExp('message', caseSensitive: false),
  ];

  static final List<RegExp> _sensitiveValuePatterns = [
    RegExp(r'sb_secret_[A-Za-z0-9_-]+'),
    RegExp(r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
    RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
  ];

  const TelemetryScrubber();

  SentryEvent? scrubEvent(SentryEvent event, Hint hint) {
    return event.copyWith(
      message: _scrubMessage(event.message),
      extra: _scrubMap(event.extra),
      breadcrumbs: event.breadcrumbs
          ?.map(_scrubBreadcrumb)
          .whereType<Breadcrumb>()
          .toList(),
    );
  }

  Breadcrumb? scrubBreadcrumb(Breadcrumb? breadcrumb, Hint hint) {
    return _scrubBreadcrumb(breadcrumb);
  }

  Breadcrumb? _scrubBreadcrumb(Breadcrumb? breadcrumb) {
    if (breadcrumb == null) return null;
    return breadcrumb.copyWith(
      message: _scrubString(breadcrumb.message),
      data: _scrubMap(breadcrumb.data),
    );
  }

  SentryMessage? _scrubMessage(SentryMessage? message) {
    if (message == null) return null;
    return message.copyWith(
      formatted: _scrubString(message.formatted),
      template: _scrubString(message.template),
      params: message.params?.map(_scrubValue).toList(),
    );
  }

  Map<String, dynamic>? _scrubMap(Map<String, dynamic>? value) {
    if (value == null) return null;
    return value.map((key, value) {
      if (_isSensitiveKey(key)) {
        return MapEntry(key, redacted);
      }
      if (_shouldHashIdentifierKey(key)) {
        return MapEntry(key, _hashIdentifier(value));
      }
      return MapEntry(key, _scrubValue(value));
    });
  }

  dynamic _scrubValue(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final keyString = key.toString();
        if (_isSensitiveKey(keyString)) {
          return MapEntry(keyString, redacted);
        }
        if (_shouldHashIdentifierKey(keyString)) {
          return MapEntry(keyString, _hashIdentifier(nestedValue));
        }
        return MapEntry(keyString, _scrubValue(nestedValue));
      });
    }
    if (value is Iterable) {
      return value.map(_scrubValue).toList();
    }
    if (value is String) {
      return _scrubString(value);
    }
    return value;
  }

  String? _scrubString(String? value) {
    if (value == null) return null;
    var scrubbed = value;
    for (final pattern in _sensitiveValuePatterns) {
      scrubbed = scrubbed.replaceAll(pattern, redacted);
    }
    return scrubbed;
  }

  bool _isSensitiveKey(String key) {
    return _sensitiveKeyPatterns.any((pattern) => pattern.hasMatch(key));
  }

  bool _shouldHashIdentifierKey(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'roomid' ||
        normalized == 'room_id' ||
        normalized == 'roundid' ||
        normalized == 'round_id' ||
        normalized == 'playerid' ||
        normalized == 'player_id' ||
        normalized == 'userid' ||
        normalized == 'user_id' ||
        normalized == 'voterid' ||
        normalized == 'voter_id' ||
        normalized == 'votedplayerid' ||
        normalized == 'voted_player_id';
  }

  String _hashIdentifier(dynamic value) {
    final input = value?.toString() ?? '';
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return 'id_${hash.toRadixString(16).padLeft(8, '0')}';
  }
}

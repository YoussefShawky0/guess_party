// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/observability/telemetry_scrubber.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('TelemetryScrubber', () {
    const scrubber = TelemetryScrubber();

    test('redacts sensitive keys from nested event extra data', () async {
      final event = SentryEvent(
        message: SentryMessage(
          'Failed with Bearer eyJabc.def.ghi and sb_secret_hidden',
        ),
        extra: {
          'room_id': 'room-1',
          'password': 'player-password',
          'authorization': 'Bearer token-value',
          'nested': {
            'character_id': 'secret-character',
            'list': [
              {'chat_content': 'hello secret'},
              'Bearer eyJabc.def.ghi',
            ],
          },
        },
      );

      final scrubbed = scrubber.scrubEvent(event, Hint());

      expect(scrubbed, isNotNull);
      expect(
        scrubbed!.message!.formatted,
        contains(TelemetryScrubber.redacted),
      );
      expect(scrubbed.message!.formatted, isNot(contains('sb_secret_hidden')));
      expect(scrubbed.extra!['room_id'], startsWith('id_'));
      expect(scrubbed.extra!['room_id'], isNot('room-1'));
      expect(scrubbed.extra!['password'], TelemetryScrubber.redacted);
      expect(scrubbed.extra!['authorization'], TelemetryScrubber.redacted);
      final nested = scrubbed.extra!['nested'] as Map;
      expect(nested['character_id'], TelemetryScrubber.redacted);
      final list = nested['list'] as List;
      expect((list.first as Map)['chat_content'], TelemetryScrubber.redacted);
      expect(list.last, contains(TelemetryScrubber.redacted));
      expect(list.last, isNot(contains('eyJabc.def.ghi')));
    });

    test('redacts sensitive breadcrumb messages and data', () {
      final breadcrumb = Breadcrumb(
        category: 'game',
        message: 'token Bearer eyJabc.def.ghi',
        data: {
          'phase': 'voting',
          'imposter_player_id': 'player-secret',
          'headers': {'Cookie': 'session=value'},
        },
      );

      final scrubbed = scrubber.scrubBreadcrumb(breadcrumb, Hint());

      expect(scrubbed, isNotNull);
      expect(scrubbed!.message, contains(TelemetryScrubber.redacted));
      expect(scrubbed.message, isNot(contains('eyJabc.def.ghi')));
      expect(scrubbed.data!['phase'], 'voting');
      expect(scrubbed.data!['imposter_player_id'], TelemetryScrubber.redacted);
      expect(
        (scrubbed.data!['headers'] as Map)['Cookie'],
        TelemetryScrubber.redacted,
      );
    });
  });
}

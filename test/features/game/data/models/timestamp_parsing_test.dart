import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/game/data/models/round_info_model.dart';
import 'package:guess_party/features/room/data/models/room_model.dart';

void main() {
  final expected = DateTime.utc(2026, 11, 16, 10, 0, 0);
  const forms = <String, String>{
    'timestamp (no offset)': '2026-11-16T10:00:00',
    'timestamptz +00:00': '2026-11-16T10:00:00+00:00',
    'Z suffix': '2026-11-16T10:00:00Z',
    'positive offset': '2026-11-16T12:00:00+02:00',
    'negative offset': '2026-11-16T05:00:00-05:00',
    'space separator': '2026-11-16 10:00:00+00',
  };

  RoundInfoModel round(String value) => RoundInfoModel.fromJson(
    {
      'id': 'r',
      'room_id': 'room',
      'imposter_player_id': null,
      'round_number': 1,
      'phase': 'hints',
      'phase_end_time': value,
    },
    null,
    const [],
    const {},
    const {},
  );

  Map<String, dynamic> roomJson(String value) => {
    'id': 'room',
    'host_id': 'host',
    'category': 'animals',
    'max_rounds': 3,
    'room_code': '123456',
    'status': 'waiting',
    'created_at': value,
  };

  Map<String, dynamic> playerJson(String value) => {
    'id': 'p',
    'user_id': 'u',
    'username': 'Player',
    'created_at': value,
    'last_seen_at': value,
  };

  group('timestamp parsing yields the same UTC instant', () {
    forms.forEach((name, value) {
      test(name, () {
        final phaseEnd = round(value).phaseEndTime;
        expect(phaseEnd, expected);
        expect(phaseEnd.isUtc, isTrue);

        final created = RoomModel.fromJson(roomJson(value)).createdAt!;
        expect(created, expected);
        expect(created.isUtc, isTrue);

        final player = PlayerModel.fromJson(playerJson(value));
        expect(player.createdAt, expected);
        expect(player.createdAt!.isUtc, isTrue);
        expect(player.lastSeenAt, expected);
      });
    });
  });

  test('fractional microseconds are preserved', () {
    final parsed = round('2026-11-16T10:00:00.123456').phaseEndTime;
    expect(parsed, DateTime.utc(2026, 11, 16, 10, 0, 0, 123, 456));
  });

  test('invalid phase_end_time is a FormatException', () {
    expect(() => round('not-a-date'), throwsFormatException);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/room/data/models/room_invite_model.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';

Map<String, dynamic> row({
  String roomId = 'r1',
  String previous = 'old',
  String userId = 'u1',
  String username = 'Ann',
  Object? status = 'pending',
  String? createdAt = '2026-11-24T10:00:00+00:00',
}) => {
  'room_id': roomId,
  'previous_room_id': previous,
  'user_id': userId,
  'username': username,
  'status': status,
  'created_at': createdAt,
};

void main() {
  group('RoomInviteModel.fromJson', () {
    test('parses every status', () {
      expect(
        RoomInviteModel.fromJson(row(status: 'accepted')).status,
        RoomInviteStatus.accepted,
      );
      expect(
        RoomInviteModel.fromJson(row(status: 'declined')).status,
        RoomInviteStatus.declined,
      );
      final pending = RoomInviteModel.fromJson(row());
      expect(pending.status, RoomInviteStatus.pending);
      expect(pending.createdAt, DateTime.utc(2026, 11, 24, 10));
      expect(pending.roomId, 'r1');
      expect(pending.previousRoomId, 'old');
    });

    test('unknown or missing status falls back to pending', () {
      expect(
        RoomInviteModel.fromJson(row(status: 'weird')).status,
        RoomInviteStatus.pending,
      );
      expect(
        RoomInviteModel.fromJson(row(status: null)).status,
        RoomInviteStatus.pending,
      );
    });

    test('createdAt is optional', () {
      expect(RoomInviteModel.fromJson(row(createdAt: null)).createdAt, isNull);
    });
  });

  group('row mappers', () {
    test('roomInvitesFromRows sorts by createdAt then username', () {
      final invites = roomInvitesFromRows([
        row(userId: 'u3', username: 'Zed', createdAt: '2026-11-24T10:00:01Z'),
        row(userId: 'u2', username: 'Bob', createdAt: '2026-11-24T10:00:00Z'),
        row(userId: 'u1', username: 'Ann', createdAt: '2026-11-24T10:00:00Z'),
      ]);
      expect(invites.map((i) => i.username), ['Ann', 'Bob', 'Zed']);
    });

    test('myRematchInvitesFromRows keeps only the given previous room', () {
      final invites = myRematchInvitesFromRows([
        row(roomId: 'a', previous: 'old'),
        row(roomId: 'b', previous: 'other'),
      ], previousRoomId: 'old');
      expect(invites.map((i) => i.roomId), ['a']);
    });
  });
}

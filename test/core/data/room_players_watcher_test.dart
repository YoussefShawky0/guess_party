import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/data/room_players_watcher.dart';

Map<String, dynamic> _row(String id, {String? createdAt, bool online = true}) =>
    {
      'id': id,
      'room_id': 'room-1',
      'user_id': 'user-$id',
      'username': 'N-$id',
      'score': 0,
      'is_host': false,
      'is_online': online,
      'created_at': createdAt,
    };

void main() {
  test('orders by created_at ascending, then id', () {
    final players = playersFromRows([
      _row('c', createdAt: '2030-01-01T10:00:02+00:00'),
      _row('b', createdAt: '2030-01-01T10:00:00+00:00'),
      _row('a', createdAt: '2030-01-01T10:00:00+00:00'),
      _row('d', createdAt: '2030-01-01T09:59:59+00:00'),
    ]);
    expect(players.map((p) => p.id), ['d', 'a', 'b', 'c']);
  });

  test('rows without created_at sort first, then by id', () {
    final players = playersFromRows([
      _row('b', createdAt: '2030-01-01T10:00:00Z'),
      _row('z'),
      _row('y'),
    ]);
    expect(players.map((p) => p.id), ['y', 'z', 'b']);
  });

  test('onlineOnly filters offline rows and keeps the same order', () {
    final rows = [
      _row('b', createdAt: '2030-01-01T10:00:01Z'),
      _row('a', createdAt: '2030-01-01T10:00:00Z', online: false),
      _row('c', createdAt: '2030-01-01T10:00:00Z'),
    ];
    expect(playersFromRows(rows).map((p) => p.id), ['a', 'c', 'b']);
    expect(playersFromRows(rows, onlineOnly: true).map((p) => p.id), [
      'c',
      'b',
    ]);
  });

  test('offset-less legacy timestamps are treated as UTC consistently', () {
    final players = playersFromRows([
      _row('b', createdAt: '2030-01-01T10:00:00'),
      _row('a', createdAt: '2030-01-01T10:00:00+00:00'),
    ]);
    expect(players.map((p) => p.id), ['a', 'b']);
  });
}

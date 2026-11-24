import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/rematch_seed.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';

Room room(String gameMode) => Room(
  id: 'room-1',
  hostId: 'h',
  category: 'animals',
  maxRounds: 4,
  currentRound: 4,
  roomCode: '123456',
  status: 'finished',
  usedCharacterIds: const [],
  maxPlayers: 5,
  roundDuration: 45,
  gameMode: gameMode,
);

Player p(String id, String name, DateTime? createdAt) => Player(
  id: id,
  roomId: 'room-1',
  userId: 'u$id',
  username: name,
  score: 0,
  isHost: false,
  createdAt: createdAt,
);

void main() {
  final players = [
    p('c', 'Cy', DateTime.utc(2026, 1, 1, 0, 0, 2)),
    p('b', 'Bob', DateTime.utc(2026, 1, 1, 0, 0, 1)),
    p('a', 'Ann', DateTime.utc(2026, 1, 1, 0, 0, 1)),
    p('z', 'Nil', null),
  ];

  test('local mode: oldest first, id as tiebreak, nulls first', () {
    final seed = RematchSeed.fromFinishedRoom(room('local'), players);
    expect(seed.localNames, ['Nil', 'Ann', 'Bob', 'Cy']);
    expect(seed.previousRoomId, 'room-1');
    expect(seed.gameMode, 'local');
    expect(seed.category, 'animals');
    expect(seed.maxRounds, 4);
    expect(seed.maxPlayers, 5);
    expect(seed.roundDuration, 45);
  });

  test('online mode: no local names', () {
    final seed = RematchSeed.fromFinishedRoom(room('online'), players);
    expect(seed.localNames, isEmpty);
    expect(seed.gameMode, 'online');
  });
}

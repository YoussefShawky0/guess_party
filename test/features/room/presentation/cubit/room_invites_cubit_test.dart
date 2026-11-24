import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/room_invites_cubit.dart';

class _FakeRepo implements RoomRepository {
  final StreamController<List<RoomInvite>> invites =
      StreamController<List<RoomInvite>>();

  @override
  Stream<List<RoomInvite>> watchRoomInvites({required String roomId}) =>
      invites.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _invite = RoomInvite(
  roomId: 'room',
  previousRoomId: 'old',
  userId: 'u1',
  username: 'Ann',
  status: RoomInviteStatus.pending,
);

void main() {
  test('is empty by default and emits the streamed list', () async {
    final repo = _FakeRepo();
    final cubit = RoomInvitesCubit(repository: repo, roomId: 'room')..start();
    expect(cubit.state, isEmpty);

    repo.invites.add([_invite]);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, [_invite]);

    repo.invites.addError(StateError('down'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, [_invite]);

    await cubit.close();
    await repo.invites.close();
  });
}

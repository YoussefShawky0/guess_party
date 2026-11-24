import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/services/analytics_service.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:guess_party/features/room/data/models/room_model.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:guess_party/features/room/presentation/cubit/rematch_invite_cubit.dart';

import '../../../../helpers/recording_analytics.dart';

class _FakeRepo implements RoomRepository {
  final StreamController<List<RoomInvite>> invites =
      StreamController<List<RoomInvite>>();
  Failure? respondFailure;
  bool respondReturnsNull = false;
  final List<(String, bool)> responses = [];

  @override
  Stream<List<RoomInvite>> watchMyRematchInvites({
    required String previousRoomId,
    required String userId,
  }) => invites.stream;

  @override
  ResultFuture<RoomSession?> respondToRematchInvite({
    required String roomId,
    required bool accept,
  }) async {
    responses.add((roomId, accept));
    if (respondFailure case final failure?) return Left(failure);
    if (!accept || respondReturnsNull) return const Right(null);
    const room = RoomModel(
      id: 'new-room',
      hostId: 'h',
      category: 'movies',
      maxRounds: 3,
      currentRound: 0,
      roomCode: '111111',
      status: 'waiting',
      usedCharacterIds: [],
      maxPlayers: 6,
      roundDuration: 60,
      gameMode: 'online',
    );
    const player = PlayerModel(
      id: 'p',
      roomId: 'new-room',
      userId: 'me',
      username: 'Me',
      score: 0,
      isHost: false,
    );
    return const Right(
      RoomSession(room: room, currentPlayer: player, players: [player]),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RoomInvite invite({
  String roomId = 'new-room',
  String previousRoomId = 'old-room',
  RoomInviteStatus status = RoomInviteStatus.pending,
  DateTime? createdAt,
}) => RoomInvite(
  roomId: roomId,
  previousRoomId: previousRoomId,
  userId: 'me',
  username: 'Me',
  status: status,
  createdAt: createdAt,
);

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeRepo repo;
  late RematchInviteCubit cubit;

  setUp(() {
    repo = _FakeRepo();
    cubit = RematchInviteCubit(
      repository: repo,
      previousRoomId: 'old-room',
      userId: 'me',
    )..start();
  });

  tearDown(() async {
    await cubit.close();
    if (!repo.invites.isClosed) await repo.invites.close();
  });

  test('starts idle, becomes invited when a pending invite arrives', () async {
    expect(cubit.state, const RematchIdle());
    repo.invites.add([invite()]);
    await pump();
    expect(cubit.state, RematchInvited(invite()));
  });

  test('ignores other previous rooms and non-pending invites', () async {
    repo.invites.add([
      invite(previousRoomId: 'other'),
      invite(roomId: 'r2', status: RoomInviteStatus.declined),
      invite(roomId: 'r3', status: RoomInviteStatus.accepted),
    ]);
    await pump();
    expect(cubit.state, const RematchIdle());
  });

  test('picks the newest pending invite', () async {
    final older = invite(roomId: 'a', createdAt: DateTime.utc(2026, 1, 1));
    final newer = invite(roomId: 'b', createdAt: DateTime.utc(2026, 1, 2));
    repo.invites.add([newer, older]);
    await pump();
    expect(cubit.state, RematchInvited(newer));
  });

  test('accept success emits joining then joined with the new room', () async {
    repo.invites.add([invite()]);
    await pump();
    final states = <RematchInviteState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.accept();
    await pump();

    expect(states, [RematchJoining(invite()), const RematchJoined('new-room')]);
    expect(repo.responses, [('new-room', true)]);
    await sub.cancel();
  });

  test('accept failure emits failed and the card does not return', () async {
    repo.respondFailure = const ServerFailure(
      'ROOM_FULL',
      code: AppErrorCode.roomFull,
    );
    repo.invites.add([invite()]);
    await pump();

    await cubit.accept();
    expect(cubit.state, const RematchFailed(AppErrorCode.roomFull));

    repo.invites.add([invite()]);
    await pump();
    expect(cubit.state, const RematchFailed(AppErrorCode.roomFull));
  });

  test('accept returning no session fails with inviteNotFound', () async {
    repo.respondReturnsNull = true;
    repo.invites.add([invite()]);
    await pump();

    await cubit.accept();
    expect(cubit.state, const RematchFailed(AppErrorCode.inviteNotFound));
  });

  test('accept without an invite does nothing', () async {
    await cubit.accept();
    expect(cubit.state, const RematchIdle());
    expect(repo.responses, isEmpty);
  });

  test('decline goes idle and stays idle when re-emitted', () async {
    repo.invites.add([invite()]);
    await pump();

    await cubit.decline();
    expect(cubit.state, const RematchIdle());
    expect(repo.responses, [('new-room', false)]);

    repo.invites.add([invite()]);
    await pump();
    expect(cubit.state, const RematchIdle());

    repo.invites.add([invite(roomId: 'another-room')]);
    await pump();
    expect(cubit.state, RematchInvited(invite(roomId: 'another-room')));
  });

  test('stream errors are swallowed', () async {
    repo.invites.add([invite()]);
    await pump();
    repo.invites.addError(StateError('down'));
    await pump();
    expect(cubit.state, RematchInvited(invite()));
  });

  group('analytics', () {
    late _FakeRepo arepo;
    late RecordingAnalytics analytics;
    late RematchInviteCubit tracked;

    setUp(() async {
      arepo = _FakeRepo();
      analytics = RecordingAnalytics();
      tracked = RematchInviteCubit(
        repository: arepo,
        previousRoomId: 'old-room',
        userId: 'me',
        analytics: analytics,
      )..start();
    });

    tearDown(() async {
      await tracked.close();
      await arepo.invites.close();
    });

    test('accepting logs accepted=true after the server succeeds', () async {
      arepo.invites.add([invite()]);
      await pump();
      await tracked.accept();

      expect(analytics.events.single, isA<RematchInviteAnsweredEvent>());
      expect(analytics.events.single.params, {'accepted': 'true'});
    });

    test('declining logs accepted=false', () async {
      arepo.invites.add([invite()]);
      await pump();
      await tracked.decline();

      expect(analytics.events.single.params, {'accepted': 'false'});
    });

    test('a failed accept logs nothing', () async {
      arepo.respondFailure = const ServerFailure(
        'ROOM_FULL',
        code: AppErrorCode.roomFull,
      );
      arepo.invites.add([invite()]);
      await pump();
      await tracked.accept();

      expect(analytics.events, isEmpty);
    });
  });

  test('does not emit after close', () async {
    final states = <RematchInviteState>[];
    cubit.stream.listen(states.add);
    await cubit.close();

    repo.invites.add([invite()]);
    await pump();
    await cubit.accept();
    await cubit.decline();

    expect(states, isEmpty);
    expect(cubit.state, const RematchIdle());
  });
}

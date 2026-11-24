import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

/// Waiting Room (host): live list of invites sent for [roomId].
class RoomInvitesCubit extends Cubit<List<RoomInvite>> {
  final RoomRepository _repository;
  final String roomId;
  StreamSubscription<List<RoomInvite>>? _subscription;

  RoomInvitesCubit({required RoomRepository repository, required this.roomId})
    : _repository = repository,
      super(const []);

  void start() {
    if (isClosed) return;
    _subscription?.cancel();
    _subscription = _repository.watchRoomInvites(roomId: roomId).listen((
      invites,
    ) {
      if (!isClosed) emit(invites);
    }, onError: (_) {});
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/room/domain/entities/room_invite.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

sealed class RematchInviteState extends Equatable {
  const RematchInviteState();

  @override
  List<Object?> get props => [];
}

/// No pending invite to show.
final class RematchIdle extends RematchInviteState {
  const RematchIdle();
}

/// A host invited this player to a new room.
final class RematchInvited extends RematchInviteState {
  final RoomInvite invite;

  const RematchInvited(this.invite);

  @override
  List<Object?> get props => [invite];
}

/// The invite is being accepted.
final class RematchJoining extends RematchInviteState {
  final RoomInvite invite;

  const RematchJoining(this.invite);

  @override
  List<Object?> get props => [invite];
}

/// The player joined the new room [roomId].
final class RematchJoined extends RematchInviteState {
  final String roomId;

  const RematchJoined(this.roomId);

  @override
  List<Object?> get props => [roomId];
}

final class RematchFailed extends RematchInviteState {
  final AppErrorCode code;

  const RematchFailed(this.code);

  @override
  List<Object?> get props => [code];
}

/// Game Over (non-host): surfaces the rematch invite for [previousRoomId].
class RematchInviteCubit extends Cubit<RematchInviteState> {
  final RoomRepository _repository;
  final String previousRoomId;
  final String userId;
  StreamSubscription<List<RoomInvite>>? _subscription;

  /// Rooms whose invite was declined or failed; hidden even if the stream
  /// re-emits them before the server update lands.
  final Set<String> _dismissedRoomIds = {};

  RematchInviteCubit({
    required RoomRepository repository,
    required this.previousRoomId,
    required this.userId,
  }) : _repository = repository,
       super(const RematchIdle());

  void start() {
    if (isClosed) return;
    _subscription?.cancel();
    _subscription = _repository
        .watchMyRematchInvites(previousRoomId: previousRoomId, userId: userId)
        .listen(_onInvites, onError: (_) {});
  }

  void _onInvites(List<RoomInvite> invites) {
    if (isClosed) return;
    if (state is RematchJoining || state is RematchJoined) return;

    RoomInvite? newest;
    for (final invite in invites) {
      if (invite.status != RoomInviteStatus.pending ||
          invite.previousRoomId != previousRoomId ||
          _dismissedRoomIds.contains(invite.roomId)) {
        continue;
      }
      if (newest == null || _isNewer(invite, newest)) newest = invite;
    }

    if (newest != null) {
      emit(RematchInvited(newest));
    } else if (state is RematchInvited) {
      emit(const RematchIdle());
    }
  }

  bool _isNewer(RoomInvite a, RoomInvite b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null || bTime == null) return aTime != null;
    return aTime.isAfter(bTime);
  }

  Future<void> accept() async {
    final current = state;
    if (isClosed || current is! RematchInvited) return;
    final invite = current.invite;
    emit(RematchJoining(invite));

    final result = await _repository.respondToRematchInvite(
      roomId: invite.roomId,
      accept: true,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        _dismissedRoomIds.add(invite.roomId);
        emit(RematchFailed(failure.code));
      },
      (session) {
        if (session == null) {
          _dismissedRoomIds.add(invite.roomId);
          emit(const RematchFailed(AppErrorCode.inviteNotFound));
        } else {
          emit(RematchJoined(session.room.id));
        }
      },
    );
  }

  Future<void> decline() async {
    final current = state;
    if (isClosed || current is! RematchInvited) return;
    final invite = current.invite;
    _dismissedRoomIds.add(invite.roomId);
    emit(const RematchIdle());

    // Best effort: the card is already gone either way.
    await _repository.respondToRematchInvite(
      roomId: invite.roomId,
      accept: false,
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    return super.close();
  }
}

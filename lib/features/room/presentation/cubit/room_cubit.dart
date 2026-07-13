import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/join_room.dart';
import 'package:guess_party/features/room/domain/usecases/mark_stale_players_offline.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/watch_room_players.dart';
import 'package:uuid/uuid.dart';
import 'package:guess_party/features/room/presentation/coordinators/room_session_coordinator.dart';

part 'room_state.dart';

class RoomCubit extends Cubit<RoomState> implements RoomSessionCoordinator {
  final CreateRoom createRoom;
  final GetRoomDetails getRoomDetails;
  final GetRoomPlayers getRoomPlayers;
  final GetRoomByCode getRoomByCode;
  final StartGame startGame;
  final UpdatePlayerStatus updatePlayerStatus;
  final MarkStalePlayersOffline markStalePlayersOffline;
  final LeaveRoom leaveRoom;
  final JoinRoom joinRoomCommand;
  final WatchRoomDetails watchRoomDetails;
  final WatchRoomPlayers watchRoomPlayers;
  StreamSubscription<Room>? _roomDetailsSubscription;
  StreamSubscription<List<Player>>? _roomPlayersSubscription;
  Timer? _roomDetailsPollTimer;
  String? _createRequestId;
  String? _createRequestFingerprint;

  @override
  int get activeSessionSubscriptionCount =>
      (_roomDetailsSubscription == null ? 0 : 1) +
      (_roomPlayersSubscription == null ? 0 : 1);

  RoomCubit({
    required this.createRoom,
    required this.getRoomDetails,
    required this.getRoomPlayers,
    required this.getRoomByCode,
    required this.startGame,
    required this.updatePlayerStatus,
    required this.markStalePlayersOffline,
    required this.leaveRoom,
    required this.joinRoomCommand,
    required this.watchRoomDetails,
    required this.watchRoomPlayers,
  }) : super(RoomInitial());

  Future<void> createNewRoom({
    required String category,
    required int maxRounds,
    required String username,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    List<String>? localPlayerNames,
  }) async {
    emit(RoomLoading());

    final localNames = gameMode == GameConstants.gameModeLocal
        ? (localPlayerNames ?? const <String>[])
        : const <String>[];
    final hostUsername = localNames.isNotEmpty ? localNames.first : username;
    final fingerprint = [
      category,
      maxRounds,
      maxPlayers,
      roundDuration,
      gameMode,
      hostUsername,
      ...localNames,
    ].join('|');
    if (_createRequestFingerprint != fingerprint) {
      _createRequestId = const Uuid().v4();
      _createRequestFingerprint = fingerprint;
    }
    _createRequestId ??= const Uuid().v4();

    final roomResult = await createRoom(
      requestId: _createRequestId!,
      category: category,
      maxRounds: maxRounds,
      maxPlayers: maxPlayers,
      roundDuration: roundDuration,
      gameMode: gameMode,
      hostUsername: hostUsername,
      localNames: localNames.length > 1 ? localNames.sublist(1) : const [],
    );

    if (isClosed) return;

    if (roomResult.isLeft()) {
      emit(RoomError(roomResult.fold((f) => f.message, (_) => '')));
      return;
    }
    final session = roomResult.getOrElse(() => throw StateError('unreachable'));
    _createRequestId = null;
    _createRequestFingerprint = null;
    emit(
      RoomWithPlayerCreated(room: session.room, player: session.currentPlayer),
    );
  }

  Future<void> loadRoomDetails({required String roomId}) async {
    emit(RoomLoading());

    final result = await getRoomDetails(roomId: roomId);

    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (room) => emit(RoomDetailsLoaded(room)),
    );
  }

  @override
  Future<void> watchRoomStatus({required String roomId}) async {
    await _roomDetailsSubscription?.cancel();
    await _roomPlayersSubscription?.cancel();
    _roomDetailsSubscription = null;
    _roomPlayersSubscription = null;
    _roomDetailsPollTimer?.cancel();

    _roomDetailsSubscription = watchRoomDetails(roomId: roomId).listen(
      _emitWatchedRoom,
      onError: (_) {
        if (!isClosed && state is! RoomDetailsLoaded) {
          emit(const RoomError('Connection lost. Reconnecting...'));
        }
      },
    );

    _roomPlayersSubscription = watchRoomPlayers(roomId: roomId).listen(
      _emitWatchedPlayers,
      onError: (_) {
        // The centralized polling fallback below preserves the last roster.
      },
    );

    _roomDetailsPollTimer = Timer.periodic(const Duration(seconds: 10), (
      _,
    ) async {
      if (isClosed) return;

      final results = await Future.wait([
        getRoomDetails(roomId: roomId),
        getRoomPlayers(roomId: roomId),
      ]);

      if (isClosed) return;

      results[0].fold((_) {}, (room) => _emitWatchedRoom(room as Room));
      results[1].fold(
        (_) {},
        (players) => _emitWatchedPlayers(players as List<Player>),
      );
    });
  }

  void _emitWatchedRoom(Room room) {
    if (isClosed) return;

    final currentState = state;
    emit(
      RoomDetailsLoaded(
        room,
        players: currentState is RoomDetailsLoaded
            ? currentState.players
            : null,
      ),
    );
  }

  void _emitWatchedPlayers(List<Player> players) {
    if (isClosed) return;
    final current = state;
    if (current is RoomDetailsLoaded) {
      emit(current.copyWith(players: players));
    }
  }

  Future<void> loadRoomPlayers({required String roomId}) async {
    // Guard against emitting after cubit is closed
    if (isClosed) return;

    final currentState = state;
    final result = await getRoomPlayers(roomId: roomId);

    // Check again after async operation
    if (isClosed) return;

    result.fold(
      (failure) {
        // Keep current waiting-room state stable on transient refresh failures.
        if (currentState is! RoomDetailsLoaded) {
          emit(RoomError(failure.message));
        }
      },
      (players) {
        if (currentState is RoomDetailsLoaded) {
          emit(currentState.copyWith(players: players));
        }
      },
    );
  }

  Future<void> startGameSession(String roomId) async {
    if (isClosed) return;

    final result = await startGame(roomId);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(RoomError(failure.message));
        }
      },
      (_) {
        // Game started successfully, state will update via Realtime
      },
    );
  }

  Future<void> setPlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
    await updatePlayerStatus(playerId: playerId, isOnline: isOnline);
  }

  Future<void> cleanUpStalePlayers({
    required String roomId,
    required int staleSeconds,
  }) async {
    // Only clean up stale players in Online Mode; skip for Local Mode
    if (state is RoomWithPlayerCreated) {
      final room = (state as RoomWithPlayerCreated).room;
      if (room.gameMode == GameConstants.gameModeLocal) return;
    } else if (state is RoomDetailsLoaded) {
      final room = (state as RoomDetailsLoaded).room;
      if (room.gameMode == GameConstants.gameModeLocal) return;
    }
    await markStalePlayersOffline(roomId: roomId, staleSeconds: staleSeconds);
  }

  Future<void> leaveRoomSession({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    // Don't emit state since the widget is being disposed
    await leaveRoom(playerId: playerId, roomId: roomId, isHost: isHost);
  }

  Future<void> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    emit(RoomLoading());

    final roomResult = await joinRoomCommand(
      roomCode: roomCode,
      username: username,
    );

    if (isClosed) return;

    roomResult.fold(
      (failure) => emit(RoomError(failure.message)),
      (session) => emit(
        RoomWithPlayerCreated(
          room: session.room,
          player: session.currentPlayer,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _roomDetailsSubscription?.cancel();
    await _roomPlayersSubscription?.cancel();
    _roomDetailsSubscription = null;
    _roomPlayersSubscription = null;
    _roomDetailsPollTimer?.cancel();
    return super.close();
  }
}

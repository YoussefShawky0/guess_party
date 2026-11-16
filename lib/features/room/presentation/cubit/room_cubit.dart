import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:guess_party/features/room/presentation/coordinators/room_session_coordinator.dart';

part 'room_state.dart';

class RoomCubit extends Cubit<RoomState> implements RoomSessionCoordinator {
  final RoomRepository _repository;
  StreamSubscription<Room>? _roomDetailsSubscription;
  StreamSubscription<List<Player>>? _roomPlayersSubscription;
  Timer? _roomDetailsPollTimer;
  final Duration _pollFallbackInterval;
  bool _roomStreamHealthy = true;
  bool _playersStreamHealthy = true;
  String? _createRequestId;
  String? _createRequestFingerprint;

  @override
  int get activeSessionSubscriptionCount =>
      (_roomDetailsSubscription == null ? 0 : 1) +
      (_roomPlayersSubscription == null ? 0 : 1);

  RoomCubit({
    required RoomRepository repository,
    Duration pollFallbackInterval = const Duration(seconds: 10),
  }) : _repository = repository,
       _pollFallbackInterval = pollFallbackInterval,
       super(RoomInitial());

  Future<void> createNewRoom({
    required String category,
    required int maxRounds,
    required String username,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    List<String>? localPlayerNames,
  }) async {
    if (isClosed) return;
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

    final roomResult = await _repository.createRoom(
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
      emit(
        RoomError(roomResult.fold((f) => f.code, (_) => AppErrorCode.unknown)),
      );
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
    if (isClosed) return;
    emit(RoomLoading());

    final result = await _repository.getRoomDetails(roomId: roomId);

    if (isClosed) return;

    result.fold(
      (failure) => emit(RoomError(failure.code)),
      (room) => emit(RoomDetailsLoaded(room)),
    );
  }

  @override
  Future<void> watchRoomStatus({required String roomId}) async {
    await _roomDetailsSubscription?.cancel();
    await _roomPlayersSubscription?.cancel();
    _roomDetailsSubscription = null;
    _roomPlayersSubscription = null;
    _stopPollFallback();
    if (isClosed) return;

    _roomStreamHealthy = true;
    _playersStreamHealthy = true;

    _roomDetailsSubscription = _repository
        .watchRoomDetails(roomId: roomId)
        .listen(
          (room) {
            _roomStreamHealthy = true;
            _stopPollFallbackIfHealthy();
            _emitWatchedRoom(room);
          },
          onError: (_) {
            _roomStreamHealthy = false;
            _startPollFallback(roomId);
            if (!isClosed && state is! RoomDetailsLoaded) {
              emit(const RoomError(AppErrorCode.network));
            }
          },
        );

    _roomPlayersSubscription = _repository
        .watchRoomPlayers(roomId: roomId)
        .listen(
          (players) {
            _playersStreamHealthy = true;
            _stopPollFallbackIfHealthy();
            _emitWatchedPlayers(players);
          },
          onError: (_) {
            // The polling fallback preserves the last roster until Realtime recovers.
            _playersStreamHealthy = false;
            _startPollFallback(roomId);
          },
        );
  }

  /// Polling is only a fallback while Realtime is unavailable.
  void _startPollFallback(String roomId) {
    if (isClosed || _roomDetailsPollTimer?.isActive == true) return;

    _roomDetailsPollTimer = Timer.periodic(_pollFallbackInterval, (_) async {
      if (isClosed) return;

      final results = await Future.wait([
        _repository.getRoomDetails(roomId: roomId),
        _repository.getRoomPlayers(roomId: roomId),
      ]);

      if (isClosed) return;

      results[0].fold((_) {}, (room) => _emitWatchedRoom(room as Room));
      results[1].fold(
        (_) {},
        (players) => _emitWatchedPlayers(players as List<Player>),
      );
    });
  }

  void _stopPollFallbackIfHealthy() {
    if (_roomStreamHealthy && _playersStreamHealthy) _stopPollFallback();
  }

  void _stopPollFallback() {
    _roomDetailsPollTimer?.cancel();
    _roomDetailsPollTimer = null;
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
    final result = await _repository.getRoomPlayers(roomId: roomId);

    // Check again after async operation
    if (isClosed) return;

    result.fold(
      (failure) {
        // Keep current waiting-room state stable on transient refresh failures.
        if (currentState is! RoomDetailsLoaded) {
          emit(RoomError(failure.code));
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

    final result = await _repository.startGame(roomId);

    if (isClosed) return;

    result.fold(
      (failure) {
        if (!isClosed) {
          emit(RoomError(failure.code));
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
    await _repository.updatePlayerStatus(
      playerId: playerId,
      isOnline: isOnline,
    );
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
    await _repository.markStalePlayersOffline(
      roomId: roomId,
      staleSeconds: staleSeconds,
    );
  }

  Future<void> leaveRoomSession({
    required String playerId,
    required String roomId,
    required bool isHost,
  }) async {
    // Don't emit state since the widget is being disposed
    await _repository.leaveRoom(
      playerId: playerId,
      roomId: roomId,
      isHost: isHost,
    );
  }

  Future<void> joinRoom({
    required String roomCode,
    required String username,
  }) async {
    if (isClosed) return;
    emit(RoomLoading());

    final roomResult = await _repository.joinRoom(
      roomCode: roomCode,
      username: username,
    );

    if (isClosed) return;

    roomResult.fold(
      (failure) => emit(RoomError(failure.code)),
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
    _stopPollFallback();
    return super.close();
  }
}

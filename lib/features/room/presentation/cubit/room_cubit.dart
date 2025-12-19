import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';
import 'package:guess_party/features/room/domain/usecases/add_player_to_room.dart';
import 'package:guess_party/features/room/domain/usecases/create_room.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_by_code.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_players.dart';
import 'package:guess_party/features/room/domain/usecases/leave_room.dart';
import 'package:guess_party/features/room/domain/usecases/start_game.dart';
import 'package:guess_party/features/room/domain/usecases/update_player_status.dart';

part 'room_state.dart';

class RoomCubit extends Cubit<RoomState> {
  final CreateRoom createRoom;
  final AddPlayerToRoom addPlayerToRoom;
  final GetRoomDetails getRoomDetails;
  final GetRoomPlayers getRoomPlayers;
  final GetRoomByCode getRoomByCode;
  final StartGame startGame;
  final UpdatePlayerStatus updatePlayerStatus;
  final LeaveRoom leaveRoom;

  RoomCubit({
    required this.createRoom,
    required this.addPlayerToRoom,
    required this.getRoomDetails,
    required this.getRoomPlayers,
    required this.getRoomByCode,
    required this.startGame,
    required this.updatePlayerStatus,
    required this.leaveRoom,
  }) : super(RoomInitial());

  Future<void> createNewRoom({
    required String category,
    required int maxRounds,
    required String username,
    required int maxPlayers,
    required int roundDuration,
  }) async {
    emit(RoomLoading());

    final roomResult = await createRoom(
      category: category,
      maxRounds: maxRounds,
      maxPlayers: maxPlayers,
      roundDuration: roundDuration,
    );

    await roomResult.fold((failure) async => emit(RoomError(failure.message)), (
      room,
    ) async {
      final playerResult = await addPlayerToRoom(
        roomId: room.id,
        username: username,
        isHost: true,
      );

      playerResult.fold(
        (failure) => emit(RoomError(failure.message)),
        (player) => emit(RoomWithPlayerCreated(room: room, player: player)),
      );
    });
  }

  Future<void> loadRoomDetails({required String roomId}) async {
    emit(RoomLoading());

    final result = await getRoomDetails(roomId: roomId);

    result.fold(
      (failure) => emit(RoomError(failure.message)),
      (room) => emit(RoomDetailsLoaded(room)),
    );
  }

  Future<void> loadRoomPlayers({required String roomId}) async {
    final result = await getRoomPlayers(roomId: roomId);

    result.fold((failure) => emit(RoomError(failure.message)), (players) {
      final currentState = state;
      if (currentState is RoomDetailsLoaded) {
        emit(currentState.copyWith(players: players));
      }
    });
  }

  Future<void> startGameSession(String roomId) async {
    final result = await startGame(roomId);
    result.fold((failure) => emit(RoomError(failure.message)), (_) {
      // Game started successfully, state will update via Realtime
    });
  }

  Future<void> setPlayerStatus({
    required String playerId,
    required bool isOnline,
  }) async {
    await updatePlayerStatus(playerId: playerId, isOnline: isOnline);
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

    final roomResult = await this.getRoomByCode(roomCode: roomCode);

    await roomResult.fold((failure) async => emit(RoomError(failure.message)), (
      room,
    ) async {
      if (room.status != 'waiting') {
        emit(const RoomError('This room has already started'));
        return;
      }

      final playerResult = await addPlayerToRoom(
        roomId: room.id,
        username: username,
        isHost: false,
      );

      playerResult.fold(
        (failure) => emit(RoomError(failure.message)),
        (player) => emit(RoomWithPlayerCreated(room: room, player: player)),
      );
    });
  }
}

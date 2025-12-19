part of 'room_cubit.dart';

sealed class RoomState extends Equatable {
  const RoomState();

  @override
  List<Object?> get props => [];
}

final class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomCreated extends RoomState {
  final Room room;

  const RoomCreated(this.room);

  @override
  List<Object?> get props => [room];
}

class RoomWithPlayerCreated extends RoomState {
  final Room room;
  final Player player;

  const RoomWithPlayerCreated({required this.room, required this.player});

  @override
  List<Object?> get props => [room, player];
}

class RoomDetailsLoaded extends RoomState {
  final Room room;
  final List<Player>? players;

  const RoomDetailsLoaded(this.room, {this.players});

  @override
  List<Object?> get props => [room, players];

  RoomDetailsLoaded copyWith({Room? room, List<Player>? players}) {
    return RoomDetailsLoaded(
      room ?? this.room,
      players: players ?? this.players,
    );
  }
}

class RoomPlayersLoaded extends RoomState {
  final List<Player> players;

  const RoomPlayersLoaded(this.players);

  @override
  List<Object?> get props => [players];
}

class RoomError extends RoomState {
  final String message;

  const RoomError(this.message);

  @override
  List<Object?> get props => [message];
}

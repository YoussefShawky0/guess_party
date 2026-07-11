import 'package:equatable/equatable.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';

class RoomSession extends Equatable {
  final Room room;
  final Player currentPlayer;
  final List<Player> players;

  const RoomSession({
    required this.room,
    required this.currentPlayer,
    required this.players,
  });

  @override
  List<Object> get props => [room, currentPlayer, players];
}

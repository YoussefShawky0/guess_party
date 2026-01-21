import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String hostId;
  final String category;
  final int maxRounds;
  final int currentRound;
  final String roomCode;
  final String status; // 'waiting', 'playing', 'finished'
  final List<String> usedCharacterIds;
  final int maxPlayers;
  final int roundDuration; // in seconds
  final String gameMode; // 'online' or 'local'
  final DateTime? createdAt;

  const Room({
    required this.id,
    required this.hostId,
    required this.category,
    required this.maxRounds,
    required this.currentRound,
    required this.roomCode,
    required this.status,
    required this.usedCharacterIds,
    required this.maxPlayers,
    required this.roundDuration,
    required this.gameMode,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    hostId,
    category,
    maxRounds,
    currentRound,
    roomCode,
    status,
    usedCharacterIds,
    maxPlayers,
    roundDuration,
    gameMode,
    createdAt,
  ];
}

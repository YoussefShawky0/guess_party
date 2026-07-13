import 'package:equatable/equatable.dart';

class Player extends Equatable {
  final String id;
  final String roomId;
  final String userId;
  final String username;
  final int score;
  final bool isHost;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? createdAt;

  const Player({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.username,
    required this.score,
    required this.isHost,
    this.isOnline = true,
    this.lastSeenAt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    userId,
    username,
    score,
    isHost,
    isOnline,
    lastSeenAt,
    createdAt,
  ];
}

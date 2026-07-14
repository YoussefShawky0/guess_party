import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.roundId,
    required this.playerId,
    required this.username,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String roomId;
  final String roundId;
  final String playerId;
  final String username;
  final String content;
  final DateTime createdAt;

  @override
  List<Object> get props => [
    id,
    roomId,
    roundId,
    playerId,
    username,
    content,
    createdAt,
  ];
}

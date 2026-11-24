import 'package:equatable/equatable.dart';

enum RoomInviteStatus { pending, accepted, declined }

class RoomInvite extends Equatable {
  final String roomId;
  final String previousRoomId;
  final String userId;
  final String username;
  final RoomInviteStatus status;
  final DateTime? createdAt;

  const RoomInvite({
    required this.roomId,
    required this.previousRoomId,
    required this.userId,
    required this.username,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    roomId,
    previousRoomId,
    userId,
    username,
    status,
    createdAt,
  ];
}

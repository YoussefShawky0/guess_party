import 'package:guess_party/features/room/domain/entities/room_invite.dart';

class RoomInviteModel extends RoomInvite {
  const RoomInviteModel({
    required super.roomId,
    required super.previousRoomId,
    required super.userId,
    required super.username,
    required super.status,
    super.createdAt,
  });

  factory RoomInviteModel.fromJson(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    return RoomInviteModel(
      roomId: json['room_id'] as String,
      previousRoomId: json['previous_room_id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      status: _statusFrom(json['status']),
      createdAt: createdAt is String
          ? DateTime.tryParse(createdAt)?.toUtc()
          : null,
    );
  }

  static RoomInviteStatus _statusFrom(Object? raw) => switch (raw) {
    'accepted' => RoomInviteStatus.accepted,
    'declined' => RoomInviteStatus.declined,
    _ => RoomInviteStatus.pending,
  };
}

/// Rows of one room's invites, oldest first then by username.
List<RoomInviteModel> roomInvitesFromRows(Iterable<Map<String, dynamic>> rows) {
  final invites = rows.map(RoomInviteModel.fromJson).toList();
  invites.sort(_byCreatedThenUsername);
  return List<RoomInviteModel>.unmodifiable(invites);
}

/// Rows of the caller's own invites, keeping only those answering
/// [previousRoomId] (the stream can apply a single server-side filter).
List<RoomInviteModel> myRematchInvitesFromRows(
  Iterable<Map<String, dynamic>> rows, {
  required String previousRoomId,
}) {
  return roomInvitesFromRows(
    rows.where((row) => row['previous_room_id'] == previousRoomId),
  );
}

int _byCreatedThenUsername(RoomInvite a, RoomInvite b) {
  final aTime = a.createdAt;
  final bTime = b.createdAt;
  if (aTime != null && bTime != null) {
    final compared = aTime.compareTo(bTime);
    if (compared != 0) return compared;
  } else if (aTime == null && bTime != null) {
    return -1;
  } else if (aTime != null && bTime == null) {
    return 1;
  }
  return a.username.compareTo(b.username);
}

import '../../domain/entities/player.dart';

class PlayerModel extends Player {
  const PlayerModel({
    required super.id,
    required super.roomId,
    required super.userId,
    required super.username,
    required super.score,
    required super.isHost,
    super.isOnline,
    super.lastSeenAt,
  });

  Player toEntity() => Player(
    id: id,
    roomId: roomId,
    userId: userId,
    username: username,
    score: score,
    isHost: isHost,
    isOnline: isOnline,
    lastSeenAt: lastSeenAt,
  );

  static DateTime _parseLastSeenAt(dynamic value) {
    if (value == null) {
      return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toUtc() ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String? ?? '',
      userId: json['user_id'] as String,
      username: json['username'] as String,
      score: json['score'] as int? ?? 0,
      isHost: json['is_host'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? true,
      lastSeenAt: _parseLastSeenAt(json['last_seen_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'username': username,
      'score': score,
      'is_host': isHost,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}

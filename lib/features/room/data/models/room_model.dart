import '../../domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.hostId,
    required super.category,
    required super.maxRounds,
    required super.currentRound,
    required super.roomCode,
    required super.status,
    required super.usedCharacterIds,
    required super.maxPlayers,
    required super.roundDuration,
    required super.gameMode,
    super.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      hostId: json['host_id'] as String,
      category: json['category'] as String,
      maxRounds: json['max_rounds'] as int,
      currentRound: json['current_round'] as int? ?? 0,
      roomCode: json['room_code'] as String,
      status: json['status'] as String,
      usedCharacterIds:
          (json['used_character_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      maxPlayers: json['max_players'] as int? ?? 6,
      roundDuration: json['round_duration'] as int? ?? 60,
      gameMode: json['game_mode'] as String? ?? 'online',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'category': category,
      'max_rounds': maxRounds,
      'current_round': currentRound,
      'room_code': roomCode,
      'status': status,
      'used_character_ids': usedCharacterIds,
      'max_players': maxPlayers,
      'round_duration': roundDuration,
      'game_mode': gameMode,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? hostId,
    String? category,
    int? maxRounds,
    int? currentRound,
    String? roomCode,
    String? status,
    List<String>? usedCharacterIds,
    int? maxPlayers,
    int? roundDuration,
    String? gameMode,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      category: category ?? this.category,
      maxRounds: maxRounds ?? this.maxRounds,
      currentRound: currentRound ?? this.currentRound,
      roomCode: roomCode ?? this.roomCode,
      status: status ?? this.status,
      usedCharacterIds: usedCharacterIds ?? this.usedCharacterIds,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      roundDuration: roundDuration ?? this.roundDuration,
      gameMode: gameMode ?? this.gameMode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

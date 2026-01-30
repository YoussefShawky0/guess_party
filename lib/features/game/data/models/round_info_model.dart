import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';

class RoundInfoModel extends RoundInfo {
  const RoundInfoModel({
    required super.id,
    required super.roomId,
    required super.imposterPlayerId,
    required super.character,
    required super.roundNumber,
    required super.phase,
    required super.phaseEndTime,
    required super.imposterRevealed,
    required super.playerIds,
    required super.playerHints,
    required super.playerVotes,
  });

  factory RoundInfoModel.fromJson(
    Map<String, dynamic> json,
    Character character,
    List<String> playerIds,
    Map<String, String?> hints,
    Map<String, String?> votes,
  ) {
    // Parse UTC timestamp and keep as UTC for comparison
    final phaseEndTimeString = json['phase_end_time'] as String;

    // Parse as UTC - database stores TIMESTAMPTZ which is UTC
    DateTime phaseEndTime;
    if (!phaseEndTimeString.endsWith('Z') &&
        !phaseEndTimeString.contains('+')) {
      // No timezone marker, treat as UTC
      phaseEndTime = DateTime.parse('${phaseEndTimeString}Z');
    } else {
      phaseEndTime = DateTime.parse(phaseEndTimeString);
    }

    // Convert to UTC explicitly
    phaseEndTime = phaseEndTime.toUtc();

    return RoundInfoModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      imposterPlayerId: json['imposter_player_id'] as String,
      character: character,
      roundNumber: json['round_number'] as int,
      phase: _parsePhase(json['phase'] as String),
      phaseEndTime: phaseEndTime,
      imposterRevealed: json['imposter_revealed'] as bool? ?? false,
      playerIds: playerIds,
      playerHints: hints,
      playerVotes: votes,
    );
  }

  static GamePhase _parsePhase(String phase) {
    switch (phase) {
      case 'hints':
        return GamePhase.hints;
      case 'voting':
        return GamePhase.voting;
      case 'results':
        return GamePhase.results;
      default:
        return GamePhase.hints;
    }
  }

  static String _phaseToString(GamePhase phase) {
    switch (phase) {
      case GamePhase.hints:
        return 'hints';
      case GamePhase.voting:
        return 'voting';
      case GamePhase.results:
        return 'results';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'imposter_player_id': imposterPlayerId,
      'character_id': character.id,
      'round_number': roundNumber,
      'phase': _phaseToString(phase),
      'phase_end_time': phaseEndTime.toIso8601String(),
      'imposter_revealed': imposterRevealed,
    };
  }

  RoundInfo toEntity() {
    return RoundInfo(
      id: id,
      roomId: roomId,
      imposterPlayerId: imposterPlayerId,
      character: character,
      roundNumber: roundNumber,
      phase: phase,
      phaseEndTime: phaseEndTime,
      imposterRevealed: imposterRevealed,
      playerIds: playerIds,
      playerHints: playerHints,
      playerVotes: playerVotes,
    );
  }
}

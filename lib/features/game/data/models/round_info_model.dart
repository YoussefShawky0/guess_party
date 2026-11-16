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
    super.submittedVoteCount,
    super.requiredVoteCount,
  });

  factory RoundInfoModel.fromJson(
    Map<String, dynamic> json,
    Character? character,
    List<String> playerIds,
    Map<String, String?> hints,
    Map<String, String?> votes, {
    int submittedVoteCount = 0,
    int requiredVoteCount = 0,
  }) {
    final phaseEndTimeString = json['phase_end_time'] as String;
    final phaseEndTime = _tryParseUtc(phaseEndTimeString);
    if (phaseEndTime == null) {
      throw FormatException('Invalid phase_end_time: $phaseEndTimeString');
    }

    return RoundInfoModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      imposterPlayerId: json['imposter_player_id'] as String?,
      character: character,
      roundNumber: json['round_number'] as int,
      phase: _parsePhase(json['phase'] as String),
      phaseEndTime: phaseEndTime,
      imposterRevealed: json['imposter_revealed'] as bool? ?? false,
      playerIds: playerIds,
      playerHints: hints,
      playerVotes: votes,
      submittedVoteCount: submittedVoteCount,
      requiredVoteCount: requiredVoteCount,
    );
  }

  /// Parses a Postgres timestamp as a UTC instant. Handles `timestamptz`
  /// values ("...+00:00", "...Z") and legacy offset-less `timestamp` values
  /// ("2026-11-16T10:00:00"), which are UTC wall-clock and must not be read as
  /// device-local time.
  static DateTime? _tryParseUtc(String raw) {
    final value = raw.trim();
    final timeStart = value.indexOf(RegExp(r'[T ]'));
    final hasOffset =
        timeStart >= 0 &&
        RegExp(r'(?:[zZ]|[+-]\d{2}(?::?\d{2})?)$')
            .hasMatch(value.substring(timeStart));
    final parsed = DateTime.tryParse(hasOffset ? value : '${value}Z');
    return parsed?.toUtc();
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
        throw FormatException('Unsupported game phase: $phase');
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
      'character_id': character?.id,
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
      submittedVoteCount: submittedVoteCount,
      requiredVoteCount: requiredVoteCount,
    );
  }
}

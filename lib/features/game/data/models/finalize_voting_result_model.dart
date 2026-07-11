import 'package:guess_party/features/game/domain/entities/finalize_voting_result.dart';

class FinalizeVotingResultModel extends FinalizeVotingResult {
  const FinalizeVotingResultModel({
    required super.roundId,
    required super.phase,
    required super.scores,
    required super.alreadyFinalized,
  });

  factory FinalizeVotingResultModel.fromJson(Map<String, dynamic> json) {
    final rawScores = json['scores'] as Map? ?? const <String, dynamic>{};
    final scores = rawScores.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );

    return FinalizeVotingResultModel(
      roundId: json['round_id'] as String,
      phase: json['phase'] as String,
      scores: Map<String, int>.unmodifiable(scores),
      alreadyFinalized: json['already_finalized'] as bool,
    );
  }
}

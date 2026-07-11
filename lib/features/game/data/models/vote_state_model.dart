import 'package:guess_party/features/game/domain/entities/vote_state.dart';

class VoteStateModel extends VoteState {
  const VoteStateModel({
    required super.votes,
    required super.submittedCount,
    required super.requiredCount,
    required super.allRequiredSubmitted,
  });

  factory VoteStateModel.fromJson(Map<String, dynamic> json) {
    final rawVotes = json['votes'] as Map? ?? const <String, dynamic>{};
    final votes = rawVotes.map(
      (key, value) => MapEntry(key.toString(), value as String),
    );

    return VoteStateModel(
      votes: Map<String, String>.unmodifiable(votes),
      submittedCount: (json['submitted_count'] as num).toInt(),
      requiredCount: (json['required_count'] as num).toInt(),
      allRequiredSubmitted: json['all_required_submitted'] as bool,
    );
  }
}

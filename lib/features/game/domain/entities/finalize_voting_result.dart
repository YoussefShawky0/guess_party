import 'package:equatable/equatable.dart';

class FinalizeVotingResult extends Equatable {
  final String roundId;
  final String phase;
  final Map<String, int> scores;
  final bool alreadyFinalized;

  const FinalizeVotingResult({
    required this.roundId,
    required this.phase,
    required this.scores,
    required this.alreadyFinalized,
  });

  @override
  List<Object> get props => [roundId, phase, scores, alreadyFinalized];
}

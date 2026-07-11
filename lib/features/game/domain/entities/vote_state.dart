import 'package:equatable/equatable.dart';

class VoteState extends Equatable {
  final Map<String, String> votes;
  final int submittedCount;
  final int requiredCount;
  final bool allRequiredSubmitted;

  const VoteState({
    required this.votes,
    required this.submittedCount,
    required this.requiredCount,
    required this.allRequiredSubmitted,
  });

  @override
  List<Object> get props => [
    votes,
    submittedCount,
    requiredCount,
    allRequiredSubmitted,
  ];
}

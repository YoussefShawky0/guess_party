import 'package:equatable/equatable.dart';

class LocalRoleRevealBundle extends Equatable {
  final String roundId;
  final String characterId;
  final String imposterPlayerId;

  const LocalRoleRevealBundle({
    required this.roundId,
    required this.characterId,
    required this.imposterPlayerId,
  });

  @override
  List<Object> get props => [roundId, characterId, imposterPlayerId];
}

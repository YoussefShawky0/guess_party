import 'package:equatable/equatable.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';

class LocalRoleRevealData extends Equatable {
  final String roundId;
  final String imposterPlayerId;
  final Character character;
  final List<Player> players;

  const LocalRoleRevealData({
    required this.roundId,
    required this.imposterPlayerId,
    required this.character,
    required this.players,
  });

  @override
  List<Object> get props => [roundId, imposterPlayerId, character, players];
}

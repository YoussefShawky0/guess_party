import 'package:guess_party/features/game/domain/entities/local_role_reveal_bundle.dart';

class LocalRoleRevealBundleModel extends LocalRoleRevealBundle {
  const LocalRoleRevealBundleModel({
    required super.roundId,
    required super.characterId,
    required super.imposterPlayerId,
  });

  factory LocalRoleRevealBundleModel.fromJson(Map<String, dynamic> json) {
    return LocalRoleRevealBundleModel(
      roundId: json['round_id'] as String,
      characterId: json['character_id'] as String,
      imposterPlayerId: json['imposter_player_id'] as String,
    );
  }
}

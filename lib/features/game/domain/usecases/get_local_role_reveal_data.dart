import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';

class GetLocalRoleRevealData {
  final GameRepository repository;

  GetLocalRoleRevealData(this.repository);

  ResultFuture<LocalRoleRevealData> call({required String roomId}) {
    return repository.getLocalRoleRevealData(roomId: roomId);
  }
}

import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/room/domain/entities/room_session.dart';
import 'package:guess_party/features/room/domain/repositories/room_repository.dart';

class CreateRoom {
  final RoomRepository repository;

  CreateRoom(this.repository);

  ResultFuture<RoomSession> call({
    required String requestId,
    required String category,
    required int maxRounds,
    required int maxPlayers,
    required int roundDuration,
    required String gameMode,
    required String hostUsername,
    required List<String> localNames,
  }) async {
    return repository.createRoom(
      requestId: requestId,
      category: category,
      maxRounds: maxRounds,
      maxPlayers: maxPlayers,
      roundDuration: roundDuration,
      gameMode: gameMode,
      hostUsername: hostUsername,
      localNames: localNames,
    );
  }
}

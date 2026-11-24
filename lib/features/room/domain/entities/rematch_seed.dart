import 'package:equatable/equatable.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/room/domain/entities/room.dart';

/// Settings of a finished room used to pre-fill the "Play Again" form.
class RematchSeed extends Equatable {
  final String previousRoomId;
  final String gameMode;
  final String category;
  final int maxRounds;
  final int maxPlayers;
  final int roundDuration;

  /// Empty for online rooms; host first for Shared-Device rooms.
  final List<String> localNames;

  const RematchSeed({
    required this.previousRoomId,
    required this.gameMode,
    required this.category,
    required this.maxRounds,
    required this.maxPlayers,
    required this.roundDuration,
    this.localNames = const [],
  });

  factory RematchSeed.fromFinishedRoom(Room room, List<Player> players) {
    final isLocal = room.gameMode == GameConstants.gameModeLocal;
    final sorted = [...players]..sort(_oldestFirst);
    return RematchSeed(
      previousRoomId: room.id,
      gameMode: room.gameMode,
      category: room.category,
      maxRounds: room.maxRounds,
      maxPlayers: room.maxPlayers,
      roundDuration: room.roundDuration,
      localNames: isLocal
          ? List<String>.unmodifiable(sorted.map((p) => p.username))
          : const [],
    );
  }

  static int _oldestFirst(Player a, Player b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime != null && bTime != null) {
      final compared = aTime.compareTo(bTime);
      if (compared != 0) return compared;
    } else if (aTime == null && bTime != null) {
      return -1;
    } else if (aTime != null && bTime == null) {
      return 1;
    }
    return a.id.compareTo(b.id);
  }

  @override
  List<Object?> get props => [
    previousRoomId,
    gameMode,
    category,
    maxRounds,
    maxPlayers,
    roundDuration,
    localNames,
  ];
}

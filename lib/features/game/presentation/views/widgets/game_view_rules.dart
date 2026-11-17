import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

/// Finds the room player matching the current user (by player id or user id).
Player? resolveCurrentRoomPlayer(GameStateEntity gameState) {
  final currentPlayerIdentifier = gameState.currentPlayerId;
  if (currentPlayerIdentifier.isEmpty) {
    return null;
  }

  for (final player in gameState.players) {
    if (player.id == currentPlayerIdentifier ||
        player.userId == currentPlayerIdentifier) {
      return player;
    }
  }

  return null;
}

/// Online host only: true when the last vote just arrived and the round is not
/// already being finalized (manual button / timer race guard).
bool shouldAutoFinalizeVoting({
  required GameLoaded previous,
  required GameLoaded current,
  required String? finalizingRoundId,
}) {
  final prevRound = previous.gameState.currentRound;
  final currRound = current.gameState.currentRound;
  final currGameState = current.gameState;

  // Only for online mode
  if (currGameState.gameMode != GameConstants.gameModeOnline) {
    return false;
  }

  // Only if current phase is voting
  if (currRound.phase != GamePhase.voting) {
    return false;
  }

  // Only if current player is host
  if (!(resolveCurrentRoomPlayer(currGameState)?.isHost ?? false)) {
    return false;
  }

  // Only if not currently finalizing (manual button or timer race guard)
  if (finalizingRoundId == currRound.id) {
    return false;
  }

  final previousComplete = prevRound.allRequiredVotesSubmitted;
  final currentComplete = currRound.allRequiredVotesSubmitted;
  final onlinePlayerCount = current.gameState.players
      .where((p) => p.isOnline)
      .length;

  // Safety: need at least 2 online players for meaningful voting
  if (onlinePlayerCount < 2) return false;

  // All conditions met once the votes just completed
  return !previousComplete && currentComplete;
}

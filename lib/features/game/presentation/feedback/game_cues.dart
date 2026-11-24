import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';

/// Seconds-remaining values (inclusive) that produce a [GameCue.tick].
bool isTickSecond(int remainingSeconds) =>
    remainingSeconds >= 1 && remainingSeconds <= 5;

/// Cues to play when the cubit moves from [previous] to [next].
///
/// Pure: no platform access. Reconnect re-emits (same round, same phase)
/// produce no cues. A first loaded state produces only `phaseStart`.
List<GameCue> cuesForTransition(GameState? previous, GameState next) {
  if (next is GameEnded) return _gameEndCues(previous, next);
  if (next is! GameLoaded) return const [];

  final round = next.gameState.currentRound;
  final prevRound = previous is GameLoaded
      ? previous.gameState.currentRound
      : null;

  if (prevRound == null) return const [GameCue.phaseStart];

  final cues = <GameCue>[];
  final newRound = prevRound.id != round.id;
  if (newRound || prevRound.phase != round.phase) {
    cues.add(GameCue.phaseStart);
  }

  // The reveal fires once per round, the first time results are visible with
  // the imposter known (the id can arrive after the phase flips).
  final revealNow =
      round.phase == GamePhase.results && round.imposterPlayerId != null;
  final revealedBefore =
      !newRound &&
      prevRound.phase == GamePhase.results &&
      prevRound.imposterPlayerId != null;
  if (revealNow && !revealedBefore) {
    cues.add(
      round.imposterCaught ? GameCue.imposterCaught : GameCue.imposterEscaped,
    );
  }
  return cues;
}

List<GameCue> _gameEndCues(GameState? previous, GameEnded next) {
  // Needs the loaded state to know the mode and who the current player is.
  if (previous is! GameLoaded) return const [];
  final game = previous.gameState;
  if (game.gameMode == GameConstants.gameModeLocal) {
    return const [GameCue.gameWon];
  }

  final scores = next.playerScores;
  var top = 0;
  for (final score in scores.values) {
    if (score > top) top = score;
  }
  final mine = scores[game.currentPlayerId] ?? 0;
  return [mine >= top ? GameCue.gameWon : GameCue.gameLost];
}

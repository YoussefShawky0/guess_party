import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/services/game_feedback.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/feedback/game_cues.dart';

import '../../../../helpers/game_test_fixtures.dart';

GameLoaded loaded(
  RoundInfo round, {
  bool reconnecting = false,
  String mode = 'online',
  String me = 'host-player',
}) => GameLoaded(
  phase2GameState(round: round).copyWith(gameMode: mode, currentPlayerId: me),
  isReconnecting: reconnecting,
);

GameEnded ended(Map<String, int> scores) =>
    GameEnded(players: phase2Players, playerScores: scores);

void main() {
  final hints = phase2Round();
  final voting = phase2Round(phase: GamePhase.voting);
  final results = phase2Round(phase: GamePhase.results);

  group('phase changes', () {
    test('first loaded emission gives only phaseStart', () {
      expect(cuesForTransition(null, loaded(hints)), [GameCue.phaseStart]);
      expect(cuesForTransition(GameLoading(), loaded(hints)), [
        GameCue.phaseStart,
      ]);
    });

    test('hints to voting gives phaseStart', () {
      expect(cuesForTransition(loaded(hints), loaded(voting)), [
        GameCue.phaseStart,
      ]);
    });

    test('next round gives phaseStart', () {
      final next = phase2Round(id: 'round-2', roundNumber: 2);
      expect(cuesForTransition(loaded(results), loaded(next)), [
        GameCue.phaseStart,
      ]);
    });

    test('same round and phase gives nothing', () {
      expect(cuesForTransition(loaded(hints), loaded(hints)), isEmpty);
    });

    test('score or hint updates inside a phase give nothing', () {
      final withHint = hints.copyWith(playerHints: {'host-player': 'x'});
      expect(cuesForTransition(loaded(hints), loaded(withHint)), isEmpty);
    });
  });

  group('imposter reveal', () {
    test('caught when the imposter is the unique top-voted player', () {
      final round = results.copyWith(
        playerVotes: {'host-player': 'guest-player'},
      );
      expect(cuesForTransition(loaded(voting), loaded(round)), [
        GameCue.phaseStart,
        GameCue.imposterCaught,
      ]);
    });

    test('escaped when someone else is the top-voted player', () {
      final round = results.copyWith(
        playerVotes: {'guest-player': 'host-player'},
      );
      expect(cuesForTransition(loaded(voting), loaded(round)), [
        GameCue.phaseStart,
        GameCue.imposterEscaped,
      ]);
    });

    test('escaped on a tie and when nobody voted', () {
      final tie = results.copyWith(
        playerVotes: {
          'host-player': 'guest-player',
          'guest-player': 'host-player',
        },
      );
      expect(cuesForTransition(loaded(voting), loaded(tie)), [
        GameCue.phaseStart,
        GameCue.imposterEscaped,
      ]);
      expect(cuesForTransition(loaded(voting), loaded(results)), [
        GameCue.phaseStart,
        GameCue.imposterEscaped,
      ]);
    });

    test('no reveal cue while the imposter is not visible', () {
      final hidden = results.copyWith(imposterPlayerId: null);
      expect(cuesForTransition(loaded(voting), loaded(hidden)), [
        GameCue.phaseStart,
      ]);
    });

    test('reveal fires when the imposter id arrives after the phase flip', () {
      final hidden = results.copyWith(imposterPlayerId: null);
      expect(cuesForTransition(loaded(hidden), loaded(results)), [
        GameCue.imposterEscaped,
      ]);
    });

    test('reveal does not repeat within the same results phase', () {
      final updated = results.copyWith(playerVotes: {'host-player': 'x'});
      expect(cuesForTransition(loaded(results), loaded(updated)), isEmpty);
    });
  });

  group('reconnect', () {
    test('reconnect re-emits give no cues', () {
      final start = loaded(hints);
      final reconnecting = loaded(hints, reconnecting: true);
      expect(cuesForTransition(start, reconnecting), isEmpty);
      expect(cuesForTransition(reconnecting, start), isEmpty);
    });

    test('reconnect re-emit during results does not repeat the reveal', () {
      expect(
        cuesForTransition(loaded(results), loaded(results, reconnecting: true)),
        isEmpty,
      );
      expect(
        cuesForTransition(loaded(results, reconnecting: true), loaded(results)),
        isEmpty,
      );
    });
  });

  group('game end', () {
    test('online top scorer wins', () {
      expect(
        cuesForTransition(
          loaded(results),
          ended({'host-player': 5, 'guest-player': 2}),
        ),
        [GameCue.gameWon],
      );
    });

    test('online tie for the top score wins', () {
      expect(
        cuesForTransition(
          loaded(results),
          ended({'host-player': 3, 'guest-player': 3}),
        ),
        [GameCue.gameWon],
      );
    });

    test('online player below the top score loses', () {
      expect(
        cuesForTransition(
          loaded(results),
          ended({'host-player': 1, 'guest-player': 4}),
        ),
        [GameCue.gameLost],
      );
    });

    test('shared-device always wins', () {
      expect(
        cuesForTransition(
          loaded(results, mode: 'local'),
          ended({'host-player': 0, 'guest-player': 9}),
        ),
        [GameCue.gameWon],
      );
    });

    test('no cue without a loaded previous state or a repeated end', () {
      final scores = {'host-player': 1};
      expect(cuesForTransition(null, ended(scores)), isEmpty);
      expect(cuesForTransition(ended(scores), ended(scores)), isEmpty);
    });
  });

  test('errors and loading give nothing', () {
    expect(cuesForTransition(loaded(hints), GameLoading()), isEmpty);
    expect(
      cuesForTransition(loaded(hints), const GameError(AppErrorCode.network)),
      isEmpty,
    );
  });

  test('tick seconds are 5 down to 1', () {
    expect([for (var s = -1; s <= 7; s++) s].where(isTickSecond), [
      1,
      2,
      3,
      4,
      5,
    ]);
  });
}

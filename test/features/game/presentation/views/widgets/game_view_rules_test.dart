import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/presentation/cubit/game_cubit.dart';
import 'package:guess_party/features/game/presentation/views/widgets/game_view_rules.dart';

import '../../../../../helpers/game_test_fixtures.dart';

GameLoaded _loaded({
  String gameMode = 'online',
  String currentPlayerId = 'host-player',
  GamePhase phase = GamePhase.voting,
  int submitted = 0,
  int required = 2,
  List<Player> players = phase2Players,
}) {
  final round = phase2Round(
    phase: phase,
  ).copyWith(submittedVoteCount: submitted, requiredVoteCount: required);
  return GameLoaded(
    phase2GameState(round: round).copyWith(
      gameMode: gameMode,
      currentPlayerId: currentPlayerId,
      players: players,
    ),
  );
}

void main() {
  group('resolveCurrentRoomPlayer', () {
    test('matches by player id', () {
      final state = _loaded(currentPlayerId: 'guest-player').gameState;
      expect(resolveCurrentRoomPlayer(state)?.id, 'guest-player');
    });

    test('matches by user id', () {
      final state = _loaded(currentPlayerId: 'guest-user').gameState;
      expect(resolveCurrentRoomPlayer(state)?.id, 'guest-player');
    });

    test('returns null for empty or unknown identifier', () {
      expect(
        resolveCurrentRoomPlayer(_loaded(currentPlayerId: '').gameState),
        isNull,
      );
      expect(
        resolveCurrentRoomPlayer(_loaded(currentPlayerId: 'nobody').gameState),
        isNull,
      );
    });
  });

  group('shouldAutoFinalizeVoting', () {
    final previous = _loaded(submitted: 1);
    final completed = _loaded(submitted: 2);

    test('true when host and last vote just arrived', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: completed,
          finalizingRoundId: null,
        ),
        isTrue,
      );
    });

    test('false outside online mode', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: _loaded(submitted: 2, gameMode: 'local'),
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });

    test('false outside voting phase', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: _loaded(submitted: 2, phase: GamePhase.hints),
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });

    test('false when current player is not host', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: _loaded(submitted: 2, currentPlayerId: 'guest-player'),
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });

    test('false while the same round is being finalized', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: completed,
          finalizingRoundId: 'round-1',
        ),
        isFalse,
      );
    });

    test('true when a different round is being finalized', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: completed,
          finalizingRoundId: 'other-round',
        ),
        isTrue,
      );
    });

    test('false with fewer than two online players', () {
      const offlineGuest = [
        Player(
          id: 'host-player',
          roomId: 'room-1',
          userId: 'host-user',
          username: 'Host',
          score: 0,
          isHost: true,
        ),
        Player(
          id: 'guest-player',
          roomId: 'room-1',
          userId: 'guest-user',
          username: 'Guest',
          score: 0,
          isHost: false,
          isOnline: false,
        ),
      ];
      expect(
        shouldAutoFinalizeVoting(
          previous: previous,
          current: _loaded(submitted: 2, players: offlineGuest),
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });

    test('false when votes were already complete before', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: completed,
          current: completed,
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });

    test('false when votes are still incomplete', () {
      expect(
        shouldAutoFinalizeVoting(
          previous: _loaded(submitted: 0),
          current: previous,
          finalizingRoundId: null,
        ),
        isFalse,
      );
    });
  });
}

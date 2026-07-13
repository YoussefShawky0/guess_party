import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';

class TestClock {
  const TestClock(this.now);

  final DateTime now;

  DateTime after(Duration duration) => now.add(duration);
}

final phase2Clock = TestClock(DateTime.utc(2030, 1, 1, 12));

const phase2Players = <Player>[
  Player(
    id: 'host-player',
    roomId: 'room-1',
    userId: 'host-user',
    username: 'Host',
    score: 0,
    isHost: true,
    isOnline: true,
  ),
  Player(
    id: 'guest-player',
    roomId: 'room-1',
    userId: 'guest-user',
    username: 'Guest',
    score: 0,
    isHost: false,
    isOnline: true,
  ),
];

RoundInfo phase2Round({
  String id = 'round-1',
  int roundNumber = 1,
  GamePhase phase = GamePhase.hints,
}) => RoundInfo(
  id: id,
  roomId: 'room-1',
  imposterPlayerId: 'guest-player',
  character: null,
  roundNumber: roundNumber,
  phase: phase,
  phaseEndTime: phase2Clock.after(const Duration(minutes: 5)),
  imposterRevealed: false,
  playerIds: const ['host-player', 'guest-player'],
  playerHints: const {},
  playerVotes: const {},
  requiredVoteCount: 2,
);

GameState phase2GameState({RoundInfo? round}) => GameState(
  roomId: 'room-1',
  currentRound: round ?? phase2Round(),
  players: phase2Players,
  currentPlayerId: 'host-player',
  totalRounds: 3,
  roundDuration: 60,
  playerScores: const {'host-player': 0, 'guest-player': 0},
  gameMode: 'online',
);

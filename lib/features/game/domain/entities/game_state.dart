import 'package:equatable/equatable.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/round_info.dart';

class GameState extends Equatable {
  final String roomId;
  final RoundInfo currentRound;
  final List<Player> players;
  final String currentPlayerId;
  final int totalRounds;
  final int roundDuration; // in seconds
  final Map<String, int> playerScores; // playerId -> score
  final String gameMode; // 'online' or 'local'

  const GameState({
    required this.roomId,
    required this.currentRound,
    required this.players,
    required this.currentPlayerId,
    required this.totalRounds,
    required this.roundDuration,
    required this.playerScores,
    required this.gameMode,
  });

  bool get isImposter => currentRound.isImposter(currentPlayerId);

  bool get canSubmitHint =>
      currentRound.phase == GamePhase.hints &&
      currentRound.getPlayerHint(currentPlayerId) == null;

  bool get canVote =>
      currentRound.phase == GamePhase.voting &&
      currentRound.getPlayerVote(currentPlayerId) == null;

  Player? getPlayer(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  int getPlayerScore(String playerId) => playerScores[playerId] ?? 0;

  List<Player> get sortedPlayers {
    final sorted = List<Player>.from(players);
    sorted.sort((a, b) => getPlayerScore(b.id).compareTo(getPlayerScore(a.id)));
    return sorted;
  }

  bool get isLastRound => currentRound.roundNumber >= totalRounds;

  GameState copyWith({
    String? roomId,
    RoundInfo? currentRound,
    List<Player>? players,
    String? currentPlayerId,
    int? totalRounds,
    int? roundDuration,
    Map<String, int>? playerScores,
    String? gameMode,
  }) {
    return GameState(
      roomId: roomId ?? this.roomId,
      currentRound: currentRound ?? this.currentRound,
      players: players ?? this.players,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      totalRounds: totalRounds ?? this.totalRounds,
      roundDuration: roundDuration ?? this.roundDuration,
      playerScores: playerScores ?? this.playerScores,
      gameMode: gameMode ?? this.gameMode,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    currentRound,
    players,
    currentPlayerId,
    totalRounds,
    roundDuration,
    playerScores,
    gameMode,
  ];
}

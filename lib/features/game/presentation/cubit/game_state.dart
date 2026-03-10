part of 'game_cubit.dart';

sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object> get props => [];
}

final class GameInitial extends GameState {}

final class GameLoading extends GameState {}

final class GameLoaded extends GameState {
  final GameStateEntity gameState;

  const GameLoaded(this.gameState);

  @override
  List<Object> get props => [gameState];
}

final class GameEnded extends GameState {
  final String message;
  final List<Player> players;
  final Map<String, int> playerScores;

  const GameEnded(
    this.message, {
    required this.players,
    required this.playerScores,
  });

  @override
  List<Object> get props => [message, players, playerScores];
}

final class GameError extends GameState {
  final String message;
  const GameError(this.message);

  @override
  List<Object> get props => [message];
}

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

final class GameHintSubmitted extends GameState {
  final String message;
  const GameHintSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

final class GameVoteSubmitted extends GameState {
  final String message;
  const GameVoteSubmitted(this.message);

  @override
  List<Object> get props => [message];
}

final class GamePhaseChanged extends GameState {
  final String newPhase;
  final String message;

  const GamePhaseChanged({required this.newPhase, required this.message});

  @override
  List<Object> get props => [newPhase, message];
}

final class GameScoresUpdated extends GameState {
  final Map<String, int> scores;
  const GameScoresUpdated(this.scores);

  @override
  List<Object> get props => [scores];
}

final class GameRoundCreated extends GameState {
  final String message;
  const GameRoundCreated(this.message);

  @override
  List<Object> get props => [message];
}

final class GameEnded extends GameState {
  final String message;
  const GameEnded(this.message);

  @override
  List<Object> get props => [message];
}

final class GameError extends GameState {
  final String message;
  const GameError(this.message);

  @override
  List<Object> get props => [message];
}

part of 'game_cubit.dart';

sealed class GameState extends Equatable {
  const GameState();

  @override
  List<Object?> get props => [];
}

final class GameInitial extends GameState {}

final class GameLoading extends GameState {}

final class GameLoaded extends GameState {
  final GameStateEntity gameState;
  final bool isReconnecting;
  final String? nonFatalMessage;
  final int nonFatalMessageId;

  const GameLoaded(
    this.gameState, {
    this.isReconnecting = false,
    this.nonFatalMessage,
    this.nonFatalMessageId = 0,
  });

  @override
  List<Object?> get props => [
    gameState,
    isReconnecting,
    nonFatalMessage,
    nonFatalMessageId,
  ];
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

  /// Monotonically increasing ID to ensure identical error messages
  /// are never deduplicated by Equatable. Each emission is unique.
  final int errorId;
  const GameError(this.message, {this.errorId = 0});

  @override
  List<Object> get props => [message, errorId];
}

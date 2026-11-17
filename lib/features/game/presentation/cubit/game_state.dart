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
  final AppErrorCode? nonFatalError;
  final int nonFatalMessageId;

  const GameLoaded(
    this.gameState, {
    this.isReconnecting = false,
    this.nonFatalError,
    this.nonFatalMessageId = 0,
  });

  @override
  List<Object?> get props => [
    gameState,
    isReconnecting,
    nonFatalError,
    nonFatalMessageId,
  ];
}

final class GameEnded extends GameState {
  final List<Player> players;
  final Map<String, int> playerScores;

  const GameEnded({required this.players, required this.playerScores});

  @override
  List<Object> get props => [players, playerScores];
}

final class GameError extends GameState {
  final AppErrorCode code;

  /// Monotonically increasing ID to ensure identical error messages
  /// are never deduplicated by Equatable. Each emission is unique.
  final int errorId;
  const GameError(this.code, {this.errorId = 0});

  @override
  List<Object> get props => [code, errorId];
}

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart'
    as entity;
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/advance_phase.dart';
import 'package:guess_party/features/game/domain/usecases/get_game_state.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';

part 'game_state.dart';

typedef GameStateEntity = entity.GameState;

class GameCubit extends Cubit<GameState> {
  final GetGameState getGameState;
  final SubmitHint submitHint;
  final SubmitVote submitVote;
  final AdvancePhase advancePhase;
  final GameRepository gameRepository;

  StreamSubscription? _roundSubscription;
  StreamSubscription? _hintsSubscription;
  StreamSubscription? _votesSubscription;

  GameCubit({
    required this.getGameState,
    required this.submitHint,
    required this.submitVote,
    required this.advancePhase,
    required this.gameRepository,
  }) : super(GameInitial());

  // Load initial game state for a room
  Future<void> loadGameState({
    required String roomId,
    required String currentPlayerId,
  }) async {
    if (isClosed) return;
    print('🎮 Loading game state for room: $roomId');
    emit(GameLoading());

    final result = await getGameState(
      roomId: roomId,
      currentPlayerId: currentPlayerId,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        print('❌ Failed to load game state: ${failure.message}');
        emit(GameError(failure.message));
      },
      (gameState) {
        print('✅ Game state loaded successfully');
        print(
          '📊 Round: ${gameState.currentRound.roundNumber}, Phase: ${gameState.currentRound.phase}',
        );
        emit(GameLoaded(gameState));
        _subscribeToGameUpdates(gameState.currentRound.id);
      },
    );
  }

  // Subscribe to real-time game updates
  void _subscribeToGameUpdates(String roundId) {
    // Subscribe to round updates
    _roundSubscription?.cancel();
    _roundSubscription = gameRepository
        .watchRoundUpdates(roundId: roundId)
        .listen((updatedRound) {
          if (!isClosed && state is GameLoaded) {
            final currentState = (state as GameLoaded).gameState;
            final updatedGameState = currentState.copyWith(
              currentRound: updatedRound,
            );
            emit(GameLoaded(updatedGameState));
          }
        });

    // Subscribe to hints updates
    _hintsSubscription?.cancel();
    _hintsSubscription = gameRepository
        .watchHintsUpdates(roundId: roundId)
        .listen((hints) {
          if (!isClosed && state is GameLoaded) {
            final currentState = (state as GameLoaded).gameState;
            // Convert Map<String, String> to Map<String, String?>
            final hintsNullable = hints.map(
              (k, v) => MapEntry(k, v as String?),
            );
            final updatedRound = currentState.currentRound.copyWith(
              playerHints: hintsNullable,
            );
            final updatedGameState = currentState.copyWith(
              currentRound: updatedRound,
            );
            emit(GameLoaded(updatedGameState));
          }
        });

    // Subscribe to votes updates
    _votesSubscription?.cancel();
    _votesSubscription = gameRepository
        .watchVotesUpdates(roundId: roundId)
        .listen((votes) {
          if (!isClosed && state is GameLoaded) {
            final currentState = (state as GameLoaded).gameState;
            // Convert Map<String, String> to Map<String, String?>
            final votesNullable = votes.map(
              (k, v) => MapEntry(k, v as String?),
            );
            final updatedRound = currentState.currentRound.copyWith(
              playerVotes: votesNullable,
            );
            final updatedGameState = currentState.copyWith(
              currentRound: updatedRound,
            );
            emit(GameLoaded(updatedGameState));
          }
        });
  }

  // Submit a hint for the current round
  Future<void> sendHint({
    required String roundId,
    required String playerId,
    required String hint,
  }) async {
    if (isClosed) return;

    final result = await submitHint(
      roundId: roundId,
      playerId: playerId,
      hint: hint,
    );

    if (isClosed) return;
    result.fold((failure) => emit(GameError(failure.message)), (_) {
      // Hint submitted successfully - realtime will update the state
      // No need to emit here, the _hintsSubscription will handle it
    });
  }

  // Submit a vote for a player
  Future<void> sendVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    if (isClosed) return;

    final result = await submitVote(
      roundId: roundId,
      voterId: voterId,
      votedPlayerId: votedPlayerId,
    );

    if (isClosed) return;
    result.fold((failure) => emit(GameError(failure.message)), (_) {
      // Vote submitted successfully - realtime will update the state
      // No need to emit here, the _votesSubscription will handle it
    });
  }

  // Advance to next phase (Host only)
  Future<void> progressPhase(String roundId) async {
    if (isClosed) return;

    final result = await advancePhase(roundId: roundId);

    if (isClosed) return;
    result.fold((failure) => emit(GameError(failure.message)), (updatedRound) {
      final phaseNames = {
        'hints': 'التلميحات',
        'voting': 'التصويت',
        'results': 'النتائج',
      };
      emit(
        GamePhaseChanged(
          newPhase: updatedRound.phase.toString(),
          message:
              'انتقلنا إلى مرحلة ${phaseNames[updatedRound.phase.toString().split('.').last]}',
        ),
      );
    });
  }

  // Calculate scores after voting (Host only)
  Future<void> calculateRoundScores(String roundId) async {
    if (isClosed) return;

    final result = await gameRepository.calculateScores(roundId: roundId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(GameError(failure.message)),
      (scores) => emit(GameScoresUpdated(scores)),
    );
  }

  // Create a new round (Host only)
  Future<void> createNewRound({
    required String roomId,
    required int roundNumber,
  }) async {
    if (isClosed) return;

    final result = await gameRepository.createNextRound(
      roomId: roomId,
      roundNumber: roundNumber,
    );

    if (isClosed) return;
    result.fold((failure) => emit(GameError(failure.message)), (newRound) {
      emit(const GameRoundCreated('New round started'));
      // Re-subscribe to updates for the new round
      _subscribeToGameUpdates(newRound.id);
    });
  }

  // End the game (Host only)
  Future<void> finishGame(String roomId) async {
    if (isClosed) return;

    final result = await gameRepository.endGame(roomId: roomId);

    if (isClosed) return;
    result.fold(
      (failure) => emit(GameError(failure.message)),
      (_) => emit(const GameEnded('انتهت اللعبة')),
    );
  }

  @override
  Future<void> close() {
    _roundSubscription?.cancel();
    _hintsSubscription?.cancel();
    _votesSubscription?.cancel();
    return super.close();
  }
}

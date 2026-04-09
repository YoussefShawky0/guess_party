import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart'
    as entity;
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/advance_phase.dart';
import 'package:guess_party/features/game/domain/usecases/get_game_state.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  /// Prevents double-tap from calling createNextRound twice (duplicate-key guard)
  bool _isCreatingRound = false;

  /// Tracks which round IDs have already had scores calculated this session
  /// Prevents calculateRoundScores from being called twice for the same round
  /// (e.g. onShowResults button + timer expiry both firing)
  final Set<String> _scoredRoundIds = {};

  /// Last successfully computed scores — fallback for calculateRoundScores if
  /// state is temporarily GameError/GameLoading
  Map<String, int> _lastKnownScores = {};

  /// The current player's Supabase auth user ID — stored once at load so the
  /// view layer does not need to access Supabase directly.
  String _currentPlayerId = '';
  String get currentPlayerId => _currentPlayerId;

  GameCubit({
    required this.getGameState,
    required this.submitHint,
    required this.submitVote,
    required this.advancePhase,
    required this.gameRepository,
  }) : super(GameInitial());

  void _addBreadcrumb(String message, {Map<String, Object?> data = const {}}) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'game',
        message: message,
        level: SentryLevel.info,
        data: data,
      ),
    );
  }

  // Load initial game state for a room
  Future<void> loadGameState({
    required String roomId,
    required String currentPlayerId,
    Map<String, int>? preservedScores,
  }) async {
    if (isClosed) return;
    _addBreadcrumb('loadGameState:start', data: {'roomId': roomId});
    _currentPlayerId = currentPlayerId;
    emit(GameLoading());

    // Sync time with server for accurate timer calculations
    await TimeSyncService.instance.syncWithServer();

    final result = await getGameState(
      roomId: roomId,
      currentPlayerId: currentPlayerId,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'loadGameState:failure',
          data: {'roomId': roomId, 'error': failure.message},
        );
        emit(GameError(failure.message));
      },
      (gameState) {
        // If preserved scores were passed (e.g. after local round transition),
        // use them instead of DB scores to maintain accurate accumulation.
        final stateToEmit =
            preservedScores != null && preservedScores.isNotEmpty
            ? gameState.copyWith(playerScores: preservedScores)
            : gameState;
        _addBreadcrumb(
          'loadGameState:success',
          data: {'roomId': roomId, 'roundId': stateToEmit.currentRound.id},
        );
        emit(GameLoaded(stateToEmit));
        _subscribeToGameUpdates(stateToEmit.currentRound.id);
      },
    );
  }

  /// Refresh game state when app is resumed.
  /// Keeps current UI state on transient network failures and retries silently.
  Future<void> refreshGameStateOnResume({
    required String roomId,
    int maxRetries = 3,
  }) async {
    if (isClosed || _currentPlayerId.isEmpty) return;

    final previousState = state;
    if (previousState is GameLoaded) {
      emit(GameLoaded(previousState.gameState, isReconnecting: true));
    }

    _addBreadcrumb(
      'resumeRefresh:start',
      data: {'roomId': roomId, 'maxRetries': maxRetries},
    );

    for (var attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await getGameState(
        roomId: roomId,
        currentPlayerId: _currentPlayerId,
      );

      if (isClosed) return;

      final succeeded = result.fold((_) => false, (_) => true);
      if (succeeded) {
        final refreshed = result.fold((_) => null, (value) => value);
        if (refreshed != null) {
          final fallbackScores = _lastKnownScores.isNotEmpty
              ? _lastKnownScores
              : refreshed.playerScores;
          final mergedState = refreshed.copyWith(playerScores: fallbackScores);

          _addBreadcrumb(
            'resumeRefresh:success',
            data: {
              'roomId': roomId,
              'attempt': attempt,
              'roundId': mergedState.currentRound.id,
            },
          );

          emit(GameLoaded(mergedState, isReconnecting: false));
          _subscribeToGameUpdates(mergedState.currentRound.id);
        }
        return;
      }

      final failure = result.fold((value) => value, (_) => null);
      _addBreadcrumb(
        'resumeRefresh:failure',
        data: {
          'roomId': roomId,
          'attempt': attempt,
          'error': failure?.message ?? 'unknown error',
        },
      );

      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: attempt));
      } else if (previousState is! GameLoaded) {
        // If there is no previously visible game state, show the error.
        emit(GameError(failure?.message ?? 'Connection error. Try again.'));
      } else {
        emit(GameLoaded(previousState.gameState, isReconnecting: false));
      }
    }
  }

  // Subscribe to real-time game updates
  void _subscribeToGameUpdates(String roundId) {
    _addBreadcrumb('subscribeToGameUpdates', data: {'roundId': roundId});
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
    _addBreadcrumb(
      'sendHint:start',
      data: {'roundId': roundId, 'playerId': playerId},
    );

    final result = await submitHint(
      roundId: roundId,
      playerId: playerId,
      hint: hint,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'sendHint:failure',
          data: {
            'roundId': roundId,
            'playerId': playerId,
            'error': failure.message,
          },
        );
        emit(GameError(failure.message));
      },
      (_) {
        // Hint submitted successfully - realtime will update the state
        // No need to emit here, the _hintsSubscription will handle it
      },
    );
  }

  // Submit a vote for a player
  Future<void> sendVote({
    required String roundId,
    required String voterId,
    required String votedPlayerId,
  }) async {
    if (isClosed) return;
    _addBreadcrumb(
      'sendVote:start',
      data: {'roundId': roundId, 'voterId': voterId},
    );

    final result = await submitVote(
      roundId: roundId,
      voterId: voterId,
      votedPlayerId: votedPlayerId,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'sendVote:failure',
          data: {
            'roundId': roundId,
            'voterId': voterId,
            'error': failure.message,
          },
        );
        emit(GameError(failure.message));
      },
      (_) {
        // Optimistic update: Update state immediately for better UX
        // Especially important in Local Mode where multiple players vote sequentially
        if (state is GameLoaded) {
          final currentState = (state as GameLoaded).gameState;
          final updatedVotes = Map<String, String?>.from(
            currentState.currentRound.playerVotes,
          );
          updatedVotes[voterId] = votedPlayerId;

          final updatedRound = currentState.currentRound.copyWith(
            playerVotes: updatedVotes,
          );
          final updatedGameState = currentState.copyWith(
            currentRound: updatedRound,
          );
          emit(GameLoaded(updatedGameState));
        }
        // Realtime subscription will sync any changes from other devices
      },
    );
  }

  // Advance to next phase (Host only)
  Future<void> progressPhase(String roundId) async {
    if (isClosed) return;
    _addBreadcrumb('progressPhase:start', data: {'roundId': roundId});

    final result = await advancePhase(roundId: roundId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'progressPhase:failure',
          data: {'roundId': roundId, 'error': failure.message},
        );
        emit(GameError(failure.message));
      },
      (updatedRound) {
        // Update the current state with new round info
        if (state is GameLoaded) {
          final currentState = (state as GameLoaded).gameState;
          final updatedGameState = currentState.copyWith(
            currentRound: updatedRound,
          );
          emit(GameLoaded(updatedGameState));
        }
      },
    );
  }

  // Calculate scores after voting (Host only)
  Future<void> calculateRoundScores(String roundId) async {
    if (isClosed) return;
    _addBreadcrumb('calculateRoundScores:start', data: {'roundId': roundId});

    // Guard: skip if already calculated for this round (prevents double scoring
    // when both the timer expiry and the "Show Results" button fire)
    if (_scoredRoundIds.contains(roundId)) return;
    _scoredRoundIds.add(roundId);

    // Use in-memory scores from current state — fallback to _lastKnownScores
    // to guard against temporarily being in GameError/GameLoading state
    Map<String, int> currentScores;
    if (state is GameLoaded) {
      currentScores = (state as GameLoaded).gameState.playerScores;
      if (currentScores.isNotEmpty) {
        _lastKnownScores = Map<String, int>.from(currentScores);
      }
    } else {
      currentScores = _lastKnownScores.isNotEmpty
          ? _lastKnownScores
          : <String, int>{};
    }

    final result = await gameRepository.calculateScores(
      roundId: roundId,
      currentScores: currentScores,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'calculateRoundScores:failure',
          data: {'roundId': roundId, 'error': failure.message},
        );
        emit(GameError(failure.message));
      },
      (scores) {
        _lastKnownScores = Map<String, int>.from(scores); // keep fallback fresh
        // Update the game state with new scores
        if (state is GameLoaded) {
          final currentState = (state as GameLoaded).gameState;
          final updatedGameState = currentState.copyWith(playerScores: scores);
          emit(GameLoaded(updatedGameState));
        }
      },
    );
  }

  // Create a new round (Host only)
  Future<void> createNewRound({
    required String roomId,
    required int roundNumber,
  }) async {
    if (isClosed || _isCreatingRound) return;
    _isCreatingRound = true;
    _addBreadcrumb(
      'createNewRound:start',
      data: {'roomId': roomId, 'roundNumber': roundNumber},
    );

    try {
      final result = await gameRepository.createNextRound(
        roomId: roomId,
        roundNumber: roundNumber,
      );

      if (isClosed) return;
      result.fold(
        (failure) {
          _addBreadcrumb(
            'createNewRound:failure',
            data: {
              'roomId': roomId,
              'roundNumber': roundNumber,
              'error': failure.message,
            },
          );
          emit(GameError(failure.message));
        },
        (newRound) {
          // Cancel old subscriptions
          _roundSubscription?.cancel();
          _hintsSubscription?.cancel();
          _votesSubscription?.cancel();

          // Clear scored-round guard for the new round
          _scoredRoundIds.clear();

          // Reload the entire game state with the new round,
          // preserving in-memory accumulated scores to avoid DB race conditions.
          if (state is GameLoaded) {
            final currentState = (state as GameLoaded).gameState;
            loadGameState(
              roomId: roomId,
              currentPlayerId: currentState.currentPlayerId,
              preservedScores: currentState.playerScores.isNotEmpty
                  ? currentState.playerScores
                  : _lastKnownScores,
            );
          }
        },
      );
    } finally {
      _isCreatingRound = false;
    }
  }

  // End the game (Host only)
  Future<void> finishGame(String roomId) async {
    if (isClosed) return;
    _addBreadcrumb('finishGame:start', data: {'roomId': roomId});

    final snapshot = state;
    final result = await gameRepository.endGame(roomId: roomId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'finishGame:failure',
          data: {'roomId': roomId, 'error': failure.message},
        );
        emit(GameError(failure.message));
      },
      (_) {
        final players = snapshot is GameLoaded
            ? snapshot.gameState.players
            : <Player>[];
        final scores = snapshot is GameLoaded
            ? snapshot.gameState.playerScores
            : <String, int>{};
        emit(GameEnded('انتهت اللعبة', players: players, playerScores: scores));
      },
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

import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart'
    as entity;
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/advance_to_voting.dart';
import 'package:guess_party/features/game/domain/usecases/create_next_round.dart';
import 'package:guess_party/features/game/domain/usecases/extend_local_role_reveal.dart';
import 'package:guess_party/features/game/domain/usecases/finalize_voting.dart';
import 'package:guess_party/features/game/domain/usecases/finish_game.dart';
import 'package:guess_party/features/game/domain/usecases/get_game_state.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'game_state.dart';

typedef GameStateEntity = entity.GameState;

class GameCubit extends Cubit<GameState> {
  static const int _minConnectedPlayersForPhaseAdvance = 2;

  final GetGameState getGameState;
  final SubmitHint submitHint;
  final SubmitVote submitVote;
  final AdvanceToVoting advanceToVoting;
  final FinalizeVoting finalizeVotingUseCase;
  final CreateNextRound createNextRound;
  final FinishGame finishGameUseCase;
  final ExtendLocalRoleReveal extendLocalRoleReveal;
  final GameRepository gameRepository;

  StreamSubscription? _roundSubscription;
  StreamSubscription? _playersSubscription;

  /// Prevents double-tap from calling createNextRound twice (duplicate-key guard)
  bool _isCreatingRound = false;

  final Set<String> _finalizingRoundIds = <String>{};
  int _nonFatalMessageIdCounter = 0;
  int _errorIdCounter = 0;

  /// The current player's Supabase auth user ID — stored once at load so the
  /// view layer does not need to access Supabase directly.
  String _currentPlayerId = '';
  String get currentPlayerId => _currentPlayerId;

  GameCubit({
    required this.getGameState,
    required this.submitHint,
    required this.submitVote,
    required this.advanceToVoting,
    required this.finalizeVotingUseCase,
    required this.createNextRound,
    required this.finishGameUseCase,
    required this.extendLocalRoleReveal,
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
    final synced = await TimeSyncService.instance.syncWithServer();
    if (!synced) {
      _addBreadcrumb(
        'loadGameState:timeSyncFailed',
        data: {'roomId': roomId, 'fallback': 'local_time'},
      );
    }

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
        _errorIdCounter++;
        emit(GameError(failure.message, errorId: _errorIdCounter));
      },
      (gameState) {
        final stateToEmit = gameState;
        _addBreadcrumb(
          'loadGameState:success',
          data: {'roomId': roomId, 'roundId': stateToEmit.currentRound.id},
        );
        emit(GameLoaded(stateToEmit));
        _subscribeToGameUpdates(
          stateToEmit.currentRound.id,
          roomId: stateToEmit.roomId,
        );
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
          final mergedState = refreshed;

          _addBreadcrumb(
            'resumeRefresh:success',
            data: {
              'roomId': roomId,
              'attempt': attempt,
              'roundId': mergedState.currentRound.id,
            },
          );

          emit(GameLoaded(mergedState, isReconnecting: false));
          _subscribeToGameUpdates(
            mergedState.currentRound.id,
            roomId: mergedState.roomId,
          );
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
        _errorIdCounter++;
        emit(
          GameError(
            failure?.message ?? 'Connection error. Try again.',
            errorId: _errorIdCounter,
          ),
        );
      } else {
        emit(GameLoaded(previousState.gameState, isReconnecting: false));
      }
    }
  }

  // Subscribe to real-time game updates
  void _subscribeToGameUpdates(String roundId, {required String roomId}) {
    unawaited(_replaceGameSubscriptions(roundId, roomId: roomId));
  }

  Future<void> _replaceGameSubscriptions(
    String roundId, {
    required String roomId,
  }) async {
    _addBreadcrumb('subscribeToGameUpdates', data: {'roundId': roundId});
    await _roundSubscription?.cancel();
    await _playersSubscription?.cancel();
    if (isClosed) return;

    _roundSubscription = gameRepository
        .watchRoundUpdates(roundId: roundId)
        .listen((updatedRound) {
          if (!isClosed && state is GameLoaded) {
            final loadedState = state as GameLoaded;
            final currentState = loadedState.gameState;
            final updatedGameState = currentState.copyWith(
              currentRound: updatedRound,
            );
            emit(
              GameLoaded(
                updatedGameState,
                isReconnecting: loadedState.isReconnecting,
              ),
            );
          }
        });

    _playersSubscription = gameRepository
        .watchRoomPlayers(roomId: roomId)
        .listen((players) {
          if (!isClosed && state is GameLoaded) {
            final loadedState = state as GameLoaded;
            final updatedGameState = loadedState.gameState.copyWith(
              players: players,
            );
            emit(
              GameLoaded(
                updatedGameState,
                isReconnecting: loadedState.isReconnecting,
              ),
            );
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
        _errorIdCounter++;
        emit(GameError(failure.message, errorId: _errorIdCounter));
      },
      (_) {
        // The safe round revision stream reloads the complete snapshot.
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
    if (voterId == votedPlayerId) {
      _addBreadcrumb(
        'sendVote:blockedSelfVote',
        data: {'roundId': roundId, 'voterId': voterId},
      );
      final currentState = state;
      if (currentState is GameLoaded) {
        _emitInlineValidationMessage(
          currentState,
          'You cannot vote for yourself',
        );
      }
      return;
    }

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
    result.fold((failure) {
      final message = failure.message;
      final lower = message.toLowerCase();
      if (message.contains('لا يمكنك التصويت لنفسك') ||
          lower.contains('cannot vote for yourself')) {
        _addBreadcrumb(
          'sendVote:selfVoteValidation',
          data: {'roundId': roundId, 'voterId': voterId},
        );
        final latestState = state;
        if (latestState is GameLoaded) {
          _emitInlineValidationMessage(
            latestState,
            'You cannot vote for yourself',
          );
        }
        return;
      }

      _addBreadcrumb(
        'sendVote:failure',
        data: {
          'roundId': roundId,
          'voterId': voterId,
          'error': failure.message,
        },
      );
      _errorIdCounter++;
      emit(GameError(failure.message, errorId: _errorIdCounter));
    }, (_) {});
  }

  // Advance to next phase (Host only)
  Future<void> progressPhase(String roundId) async {
    if (isClosed) return;
    _addBreadcrumb('progressPhase:start', data: {'roundId': roundId});

    // Non-fatal guard: skip/advance is allowed only with >= 2 connected players
    final currentState = state;
    if (currentState is GameLoaded) {
      final connectedPlayers = _connectedPlayersForCurrentRound(
        gameLoaded: currentState,
        roundId: roundId,
      );
      if (connectedPlayers < _minConnectedPlayersForPhaseAdvance) {
        _emitInlineValidationMessage(
          currentState,
          'Not enough connected players. Minimum '
          '$_minConnectedPlayersForPhaseAdvance required to skip/advance.',
        );
        return;
      }
    }

    if (currentState is! GameLoaded) return;
    if (currentState.gameState.currentRound.phase == GamePhase.voting) {
      await finalizeVoting(roundId, 'host_skip');
      return;
    }

    final result = await advanceToVoting(roundId: roundId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'progressPhase:failure',
          data: {'roundId': roundId, 'error': failure.message},
        );
        final latestState = state;
        if (latestState is GameLoaded &&
            _isNonFatalPhaseAdvanceValidationFailure(failure.message)) {
          _emitInlineValidationMessage(latestState, failure.message);
          return;
        }
        _errorIdCounter++;
        emit(GameError(failure.message, errorId: _errorIdCounter));
      },
      (updatedRound) {
        // Update the current state with new round info
        if (state is GameLoaded) {
          final loadedState = state as GameLoaded;
          final currentState = loadedState.gameState;
          final updatedGameState = currentState.copyWith(
            currentRound: updatedRound,
          );
          emit(
            GameLoaded(
              updatedGameState,
              isReconnecting: loadedState.isReconnecting,
            ),
          );
        }
      },
    );
  }

  Future<void> finalizeVoting(String roundId, String reason) async {
    if (isClosed || !_finalizingRoundIds.add(roundId)) return;
    _addBreadcrumb(
      'finalizeVoting:start',
      data: {'roundId': roundId, 'reason': reason},
    );

    try {
      final result = await finalizeVotingUseCase(
        roundId: roundId,
        reason: reason,
      );
      if (isClosed) return;

      result.fold(
        (failure) {
          _addBreadcrumb(
            'finalizeVoting:failure',
            data: {'roundId': roundId, 'error': failure.message},
          );
          final current = state;
          if (current is GameLoaded) {
            _emitInlineValidationMessage(current, failure.message);
          }
        },
        (finalized) {
          if (state is GameLoaded) {
            final loadedState = state as GameLoaded;
            final updatedGameState = loadedState.gameState.copyWith(
              playerScores: finalized.scores,
            );
            emit(
              GameLoaded(
                updatedGameState,
                isReconnecting: loadedState.isReconnecting,
              ),
            );
          }
        },
      );
    } finally {
      _finalizingRoundIds.remove(roundId);
    }
  }

  // Create a new round (Host only)
  Future<bool> createNewRound({
    required String roomId,
    required int roundNumber,
  }) async {
    if (isClosed || _isCreatingRound) return false;
    _isCreatingRound = true;
    _addBreadcrumb(
      'createNewRound:start',
      data: {'roomId': roomId, 'roundNumber': roundNumber},
    );

    try {
      final result = await createNextRound(
        roomId: roomId,
        expectedRoundNumber: roundNumber,
      );

      if (isClosed) return false;
      var succeeded = false;
      await result.fold(
        (failure) {
          _addBreadcrumb(
            'createNewRound:failure',
            data: {
              'roomId': roomId,
              'roundNumber': roundNumber,
              'error': failure.message,
            },
          );
          _errorIdCounter++;
          emit(GameError(failure.message, errorId: _errorIdCounter));
        },
        (newRound) async {
          if (state is GameLoaded) {
            final loaded = state as GameLoaded;
            emit(
              GameLoaded(
                loaded.gameState.copyWith(currentRound: newRound),
                isReconnecting: loaded.isReconnecting,
              ),
            );
          }
          await _replaceGameSubscriptions(newRound.id, roomId: roomId);
          succeeded = true;
        },
      );
      return succeeded;
    } finally {
      _isCreatingRound = false;
    }
  }

  // Adjust round timer by adding additional seconds (for local mode role reveals)
  Future<void> adjustRoundTimer({
    required String roundId,
    required int additionalSeconds,
  }) async {
    if (isClosed) return;
    _addBreadcrumb(
      'adjustRoundTimer:start',
      data: {'roundId': roundId, 'additionalSeconds': additionalSeconds},
    );

    final result = await extendLocalRoleReveal(
      roundId: roundId,
      seconds: additionalSeconds,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'adjustRoundTimer:failure',
          data: {'roundId': roundId, 'error': failure.message},
        );
      },
      (_) {
        _addBreadcrumb(
          'adjustRoundTimer:success',
          data: {'roundId': roundId, 'seconds': additionalSeconds},
        );
      },
    );
  }

  // End the game (Host only)
  Future<void> finishGame(String roomId) async {
    if (isClosed) return;
    _addBreadcrumb('finishGame:start', data: {'roomId': roomId});

    final snapshot = state;
    final result = await finishGameUseCase(roomId: roomId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'finishGame:failure',
          data: {'roomId': roomId, 'error': failure.message},
        );
        _errorIdCounter++;
        emit(GameError(failure.message, errorId: _errorIdCounter));
      },
      (_) {
        final players = snapshot is GameLoaded
            ? snapshot.gameState.players
            : <Player>[];
        final scores = snapshot is GameLoaded
            ? snapshot.gameState.playerScores
            : <String, int>{};
        // Step 15: English text consistency
        emit(GameEnded('Game Over', players: players, playerScores: scores));
      },
    );
  }

  int _connectedPlayersForCurrentRound({
    required GameLoaded gameLoaded,
    required String roundId,
  }) {
    final currentRound = gameLoaded.gameState.currentRound;
    final roundPlayerIds = currentRound.id == roundId
        ? currentRound.playerIds.toSet()
        : <String>{};

    return gameLoaded.gameState.players
        .where(
          (player) =>
              player.isOnline &&
              (roundPlayerIds.isEmpty || roundPlayerIds.contains(player.id)),
        )
        .length;
  }

  bool _isNonFatalPhaseAdvanceValidationFailure(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('not enough players') ||
        normalized.contains('minimum 2') ||
        normalized.contains('only the current host') ||
        normalized.contains('not authorized') ||
        normalized.contains('permission');
  }

  void _emitInlineValidationMessage(GameLoaded currentState, String message) {
    _nonFatalMessageIdCounter++;
    emit(
      GameLoaded(
        currentState.gameState,
        isReconnecting: currentState.isReconnecting,
        nonFatalMessage: message,
        nonFatalMessageId: _nonFatalMessageIdCounter,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _roundSubscription?.cancel();
    await _playersSubscription?.cancel();
    await super.close();
  }
}

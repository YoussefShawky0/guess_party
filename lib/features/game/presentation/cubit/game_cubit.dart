import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/utils/time_sync_service.dart';
import 'package:guess_party/features/auth/domain/entities/player.dart';
import 'package:guess_party/features/game/domain/entities/game_state.dart'
    as entity;
import 'package:guess_party/features/game/domain/entities/round_info.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/domain/usecases/submit_hint.dart';
import 'package:guess_party/features/game/domain/usecases/submit_vote.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:guess_party/features/game/presentation/coordinators/online_game_coordinator.dart';

part 'game_state.dart';

typedef GameStateEntity = entity.GameState;

class GameCubit extends Cubit<GameState> implements OnlineGameCoordinator {
  static const int _minConnectedPlayersForPhaseAdvance =
      minConnectedPlayersToAdvance;

  final GameRepository gameRepository;
  final TimeSyncService timeSyncService;

  // Hint/vote validation lives in these use cases; every other game command
  // goes straight to the repository.
  late final SubmitHint _submitHint = SubmitHint(gameRepository);
  late final SubmitVote _submitVote = SubmitVote(gameRepository);

  final StreamController<void> _voteAcceptedController =
      StreamController<void>.broadcast();

  /// Fires after the server accepted the current player's vote (for feedback
  /// cues only; never carries game state).
  Stream<void> get voteAccepted => _voteAcceptedController.stream;

  /// Server-synchronized current time, used by phase timers.
  DateTime get serverNow => timeSyncService.serverTime;

  StreamSubscription? _roundSubscription;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _roomStatusSubscription;

  @override
  int get activeOnlineGameSubscriptionCount =>
      (_roundSubscription == null ? 0 : 1) +
      (_playersSubscription == null ? 0 : 1) +
      (_roomStatusSubscription == null ? 0 : 1);

  /// Incremented every time subscriptions are replaced (or the cubit closes) so
  /// a stale concurrent replacement never assigns or leaks streams.
  int _subscriptionGeneration = 0;

  /// Prevents double-tap from calling createNextRound twice (duplicate-key guard)
  bool _isCreatingRound = false;

  final Set<String> _finalizingRoundIds = <String>{};
  int _nonFatalMessageIdCounter = 0;
  int _errorIdCounter = 0;

  /// The current player's Supabase auth user ID — stored once at load so the
  /// view layer does not need to access Supabase directly.
  String _currentPlayerId = '';
  String get currentPlayerId => _currentPlayerId;

  GameCubit({required this.gameRepository, required this.timeSyncService})
    : super(GameInitial());

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
    final synced = await timeSyncService.syncWithServer();
    if (!synced) {
      _addBreadcrumb(
        'loadGameState:timeSyncFailed',
        data: {'roomId': roomId, 'fallback': 'local_time'},
      );
    }

    final result = await gameRepository.getGameState(
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
        emit(GameError(failure.code, errorId: _errorIdCounter));
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
  @override
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
      final result = await gameRepository.getGameState(
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
            failure?.code ?? AppErrorCode.network,
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
    final generation = ++_subscriptionGeneration;
    final previous = <StreamSubscription?>[
      _roundSubscription,
      _playersSubscription,
      _roomStatusSubscription,
    ];
    _roundSubscription = null;
    _playersSubscription = null;
    _roomStatusSubscription = null;
    await Future.wait<void>([
      for (final subscription in previous)
        if (subscription != null) subscription.cancel(),
    ]);
    // A newer replacement (or close) superseded this one while cancelling.
    if (isClosed || generation != _subscriptionGeneration) return;

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

    _roomStatusSubscription = gameRepository
        .watchRoomStatus(roomId: roomId)
        .listen((status) {
          if (!isClosed && status == 'finished' && state is GameLoaded) {
            final loaded = state as GameLoaded;
            emit(
              GameEnded(
                players: loaded.gameState.players,
                playerScores: loaded.gameState.playerScores,
              ),
            );
          }
        });
  }

  @override
  Future<void> setCurrentPlayerPresence({
    required String roomId,
    required String userId,
    required bool isOnline,
  }) async {
    await gameRepository.updateCurrentPlayerPresence(
      roomId: roomId,
      userId: userId,
      isOnline: isOnline,
    );
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

    final result = await _submitHint(
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
        _emitActionFailure(failure.code);
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
        _emitInlineValidationMessage(currentState, AppErrorCode.selfVote);
      }
      return;
    }

    _addBreadcrumb(
      'sendVote:start',
      data: {'roundId': roundId, 'voterId': voterId},
    );

    final result = await _submitVote(
      roundId: roundId,
      voterId: voterId,
      votedPlayerId: votedPlayerId,
    );

    if (isClosed) return;
    result.fold(
      (failure) {
        if (failure.code == AppErrorCode.selfVote) {
          _addBreadcrumb(
            'sendVote:selfVoteValidation',
            data: {'roundId': roundId, 'voterId': voterId},
          );
          final latestState = state;
          if (latestState is GameLoaded) {
            _emitInlineValidationMessage(latestState, AppErrorCode.selfVote);
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
        _emitActionFailure(failure.code);
      },
      (_) {
        if (!_voteAcceptedController.isClosed) {
          _voteAcceptedController.add(null);
        }
      },
    );
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
          AppErrorCode.notEnoughPlayersToAdvance,
        );
        return;
      }
    }

    if (currentState is! GameLoaded) return;
    if (currentState.gameState.currentRound.phase == GamePhase.voting) {
      await finalizeVoting(roundId, 'host_skip');
      return;
    }

    final result = await gameRepository.advanceToVoting(roundId: roundId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'progressPhase:failure',
          data: {'roundId': roundId, 'error': failure.message},
        );
        _emitActionFailure(failure.code);
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
      final result = await gameRepository.finalizeVoting(
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
            _emitInlineValidationMessage(current, failure.code);
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
      final result = await gameRepository.createNextRound(
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
          _emitActionFailure(failure.code);
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

    final result = await gameRepository.extendLocalRoleReveal(
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
    final result = await gameRepository.finishGame(roomId: roomId);

    if (isClosed) return;
    result.fold(
      (failure) {
        _addBreadcrumb(
          'finishGame:failure',
          data: {'roomId': roomId, 'error': failure.message},
        );
        _emitActionFailure(failure.code);
      },
      (_) {
        final players = snapshot is GameLoaded
            ? snapshot.gameState.players
            : <Player>[];
        final scores = snapshot is GameLoaded
            ? snapshot.gameState.playerScores
            : <String, int>{};
        emit(GameEnded(players: players, playerScores: scores));
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

  /// Recoverable action failures keep the visible game (snackbar via
  /// [GameLoaded.nonFatalMessage]); only fall back to [GameError] when there is
  /// no loaded state to preserve.
  void _emitActionFailure(AppErrorCode code) {
    final current = state;
    if (current is GameLoaded) {
      _emitInlineValidationMessage(current, code);
      return;
    }
    _errorIdCounter++;
    emit(GameError(code, errorId: _errorIdCounter));
  }

  void _emitInlineValidationMessage(
    GameLoaded currentState,
    AppErrorCode code,
  ) {
    _nonFatalMessageIdCounter++;
    emit(
      GameLoaded(
        currentState.gameState,
        isReconnecting: currentState.isReconnecting,
        nonFatalError: code,
        nonFatalMessageId: _nonFatalMessageIdCounter,
      ),
    );
  }

  @override
  Future<void> close() async {
    _subscriptionGeneration++;
    await _roundSubscription?.cancel();
    await _playersSubscription?.cancel();
    await _roomStatusSubscription?.cancel();
    _roundSubscription = null;
    _playersSubscription = null;
    _roomStatusSubscription = null;
    await _voteAcceptedController.close();
    await super.close();
  }
}

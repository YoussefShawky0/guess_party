import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/constants/game_constants.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/room/domain/usecases/get_room_details.dart';

sealed class CountdownState extends Equatable {
  const CountdownState();

  @override
  List<Object?> get props => [];
}

/// Initial state, and the state while the first round is being looked up.
final class CountdownCounting extends CountdownState {
  const CountdownCounting();
}

/// The first round exists; the view may navigate to [gameMode]'s screen.
final class CountdownReady extends CountdownState {
  final String gameMode;

  const CountdownReady(this.gameMode);

  bool get isLocal => gameMode == GameConstants.gameModeLocal;

  @override
  List<Object?> get props => [gameMode];
}

/// No round could be loaded after all attempts. Recoverable via retry.
final class CountdownRoundUnavailable extends CountdownState {
  final AppErrorCode code;

  const CountdownRoundUnavailable(this.code);

  @override
  List<Object?> get props => [code];
}

/// Confirms the first round exists before the game screen is opened.
///
/// The DB trigger that creates the first round should have run by the time the
/// countdown ends, but slow networks can delay it, so the lookup is polled.
class CountdownCubit extends Cubit<CountdownState> {
  final GameRepository _gameRepository;
  final GetRoomDetails _getRoomDetails;
  final String roomId;
  final int maxAttempts;
  final Duration pollInterval;

  bool _resolving = false;

  CountdownCubit({
    required GameRepository gameRepository,
    required GetRoomDetails getRoomDetails,
    required this.roomId,
    this.maxAttempts = 5,
    this.pollInterval = const Duration(seconds: 1),
  }) : _gameRepository = gameRepository,
       _getRoomDetails = getRoomDetails,
       super(const CountdownCounting());

  /// Polls for the first round, then emits [CountdownReady] or
  /// [CountdownRoundUnavailable]. Safe to call again as a retry.
  Future<void> resolveRound() async {
    if (_resolving) return;
    _resolving = true;
    try {
      emit(const CountdownCounting());

      AppErrorCode lastCode = AppErrorCode.roundNotFound;
      var found = false;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        try {
          final result = await _gameRepository.getCurrentRound(roomId: roomId);
          if (isClosed) return;
          final failure = result.fold<AppErrorCode?>(
            (f) => f.code,
            (_) => null,
          );
          if (failure == null) {
            found = true;
            break;
          }
          lastCode = failure;
        } catch (e) {
          if (isClosed) return;
          lastCode = appErrorCodeFrom(e);
        }
        if (attempt < maxAttempts - 1) {
          await Future<void>.delayed(pollInterval);
          if (isClosed) return;
        }
      }

      if (!found) {
        emit(CountdownRoundUnavailable(lastCode));
        return;
      }

      // Never guess the mode: routing a local room to the online screen (or
      // vice versa) breaks Online/Shared-Device separation. Retry instead.
      final AppErrorCode? modeError;
      String? gameMode;
      try {
        final result = await _getRoomDetails(roomId: roomId);
        modeError = result.fold((f) => f.code, (room) {
          gameMode = room.gameMode;
          return null;
        });
      } catch (e) {
        if (isClosed) return;
        emit(CountdownRoundUnavailable(appErrorCodeFrom(e)));
        return;
      }
      if (isClosed) return;
      if (modeError != null || gameMode == null) {
        emit(CountdownRoundUnavailable(modeError ?? AppErrorCode.unknown));
        return;
      }
      emit(CountdownReady(gameMode!));
    } finally {
      _resolving = false;
    }
  }
}

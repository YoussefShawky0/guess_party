import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/usecases/extend_local_role_reveal.dart';
import 'package:guess_party/features/game/domain/usecases/get_local_role_reveal_data.dart';

sealed class LocalRoleRevealState extends Equatable {
  const LocalRoleRevealState();

  @override
  List<Object?> get props => [];
}

final class LocalRoleRevealInitial extends LocalRoleRevealState {}

final class LocalRoleRevealLoading extends LocalRoleRevealState {}

final class LocalRoleRevealLoaded extends LocalRoleRevealState {
  final LocalRoleRevealData data;

  const LocalRoleRevealLoaded(this.data);

  @override
  List<Object> get props => [data];
}

final class LocalRoleRevealFailure extends LocalRoleRevealState {
  final String message;

  const LocalRoleRevealFailure(this.message);

  @override
  List<Object> get props => [message];
}

class LocalRoleRevealCubit extends Cubit<LocalRoleRevealState> {
  final GetLocalRoleRevealData getLocalRoleRevealData;
  final ExtendLocalRoleReveal extendLocalRoleReveal;

  LocalRoleRevealCubit({
    required this.getLocalRoleRevealData,
    required this.extendLocalRoleReveal,
  }) : super(LocalRoleRevealInitial());

  Future<void> load(String roomId) async {
    emit(LocalRoleRevealLoading());
    final result = await getLocalRoleRevealData(roomId: roomId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LocalRoleRevealFailure(failure.message)),
      (data) => emit(LocalRoleRevealLoaded(data)),
    );
  }

  Future<bool> extendReveal({
    required String roundId,
    required int seconds,
  }) async {
    final result = await extendLocalRoleReveal(
      roundId: roundId,
      seconds: seconds.clamp(5, 300).toInt(),
    );
    return result.fold((_) => false, (_) => true);
  }

  void clearSecrets() {
    if (!isClosed) emit(LocalRoleRevealInitial());
  }
}

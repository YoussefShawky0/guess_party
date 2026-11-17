import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;

  HomeCubit({required HomeRepository repository})
    : _repository = repository,
      super(HomeInitial());

  Future<void> loadUserInfo() async {
    if (isClosed) return;
    emit(HomeLoading());

    final result = await _repository.getCurrentUser();

    if (isClosed) return;

    result.fold(
      (failure) => emit(HomeError(code: failure.code)),
      (userInfo) => emit(HomeLoaded(userInfo: userInfo)),
    );
  }

  Future<void> signOutUser() async {
    if (isClosed) return;
    final result = await _repository.signOut();

    if (isClosed) return;

    result.fold(
      (failure) => emit(HomeError(code: failure.code)),
      (_) => emit(HomeSignedOut()),
    );
  }
}

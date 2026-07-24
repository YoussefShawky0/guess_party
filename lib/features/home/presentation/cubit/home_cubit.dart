import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/features/home/domain/usecases/get_current_user.dart';
import 'package:guess_party/features/home/domain/usecases/sign_out.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetCurrentUser getCurrentUser;
  final SignOut signOut;

  HomeCubit({required this.getCurrentUser, required this.signOut})
    : super(HomeInitial());

  Future<void> loadUserInfo() async {
    if (isClosed) return;
    emit(HomeLoading());

    final result = await getCurrentUser();

    if (isClosed) return;

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (userInfo) => emit(HomeLoaded(userInfo: userInfo)),
    );
  }

  Future<void> signOutUser() async {
    if (isClosed) return;
    final result = await signOut();

    if (isClosed) return;

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (_) => emit(HomeSignedOut()),
    );
  }
}

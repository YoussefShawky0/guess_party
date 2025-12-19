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
    emit(HomeLoading());

    final result = await getCurrentUser();

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (userInfo) => emit(HomeLoaded(userInfo: userInfo)),
    );
  }

  Future<void> signOutUser() async {
    final result = await signOut();

    result.fold(
      (failure) => emit(HomeError(message: failure.message)),
      (_) => emit(HomeSignedOut()),
    );
  }
}

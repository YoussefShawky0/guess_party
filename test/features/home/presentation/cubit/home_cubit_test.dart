import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/domain/usecases/get_current_user.dart';
import 'package:guess_party/features/home/domain/usecases/sign_out.dart';
import 'package:guess_party/features/home/presentation/cubit/home_cubit.dart';
import 'package:guess_party/features/home/presentation/cubit/home_state.dart';

void main() {
  test('emits signed out when the cubit remains active', () async {
    final repository = _ControlledHomeRepository();
    final cubit = _buildCubit(repository);
    addTearDown(cubit.close);
    final stateExpectation = expectLater(
      cubit.stream,
      emits(isA<HomeSignedOut>()),
    );

    final signOutFuture = cubit.signOutUser();
    repository.completeSignOut();

    await signOutFuture;
    await stateExpectation;
  });

  test('does not emit when sign out finishes after the cubit closes', () async {
    final repository = _ControlledHomeRepository();
    final cubit = _buildCubit(repository);

    final signOutFuture = cubit.signOutUser();
    await cubit.close();
    repository.completeSignOut();

    await expectLater(signOutFuture, completes);
    expect(cubit.isClosed, isTrue);
  });
}

HomeCubit _buildCubit(HomeRepository repository) {
  return HomeCubit(
    getCurrentUser: GetCurrentUser(repository),
    signOut: SignOut(repository),
  );
}

class _ControlledHomeRepository implements HomeRepository {
  final _signOutCompleter = Completer<Either<Failure, void>>();

  void completeSignOut() {
    _signOutCompleter.complete(const Right<Failure, void>(null));
  }

  @override
  Future<Either<Failure, UserInfo>> getCurrentUser() async {
    return const Right(
      UserInfo(
        id: 'user-id',
        username: 'Tester',
        isAnonymous: false,
        email: 'tester@example.com',
        isLegacyAccount: false,
      ),
    );
  }

  @override
  Future<Either<Failure, void>> signOut() => _signOutCompleter.future;

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    return const Right<Failure, void>(null);
  }
}

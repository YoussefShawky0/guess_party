import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/game/domain/entities/character.dart';
import 'package:guess_party/features/game/domain/entities/local_role_reveal_data.dart';
import 'package:guess_party/features/game/domain/repositories/game_repository.dart';
import 'package:guess_party/features/game/presentation/cubit/local_role_reveal_cubit.dart';

import '../../../../helpers/game_test_fixtures.dart';

const _character = Character(
  id: 'c1',
  name: 'Cat',
  emoji: 'x',
  category: 'animals',
  difficulty: 'easy',
  isActive: true,
);

class _FakeGameRepository extends Fake implements GameRepository {
  _FakeGameRepository(this.result);

  final Either<Failure, LocalRoleRevealData> result;

  @override
  Future<Either<Failure, LocalRoleRevealData>> getLocalRoleRevealData({
    required String roomId,
  }) async => result;
}

LocalRoleRevealCubit _cubit(Either<Failure, LocalRoleRevealData> result) =>
    LocalRoleRevealCubit(repository: _FakeGameRepository(result));

void main() {
  test('valid data loads', () async {
    final data = LocalRoleRevealData(
      roundId: 'r1',
      imposterPlayerId: 'guest-player',
      character: _character,
      players: phase2Players,
    );
    final cubit = _cubit(Right(data));
    await cubit.load('room-1');
    expect(cubit.state, LocalRoleRevealLoaded(data));
    await cubit.close();
  });

  test('successful load with empty players emits failure', () async {
    final cubit = _cubit(
      const Right(
        LocalRoleRevealData(
          roundId: 'r1',
          imposterPlayerId: 'p1',
          character: _character,
          players: [],
        ),
      ),
    );
    await cubit.load('room-1');
    expect(
      cubit.state,
      const LocalRoleRevealFailure(AppErrorCode.roundNotFound),
    );
    await cubit.close();
  });

  test('successful load with missing round id emits failure', () async {
    final cubit = _cubit(
      Right(
        LocalRoleRevealData(
          roundId: '',
          imposterPlayerId: 'p1',
          character: _character,
          players: phase2Players,
        ),
      ),
    );
    await cubit.load('room-1');
    expect(cubit.state, isA<LocalRoleRevealFailure>());
    await cubit.close();
  });
}

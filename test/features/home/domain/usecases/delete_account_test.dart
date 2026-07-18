import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';
import 'package:guess_party/features/home/domain/usecases/delete_account.dart';

class _FakeHomeRepository implements HomeRepository {
  _FakeHomeRepository(this.result);

  final Either<Failure, void> result;
  var deleteCalls = 0;

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    deleteCalls++;
    return result;
  }

  @override
  Future<Either<Failure, UserInfo>> getCurrentUser() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> signOut() async => throw UnimplementedError();
}

void main() {
  test('delegates account deletion to the repository', () async {
    final repository = _FakeHomeRepository(const Right(null));

    final result = await DeleteAccount(repository)();

    expect(result, const Right<Failure, void>(null));
    expect(repository.deleteCalls, 1);
  });

  test('preserves deletion failures for the presentation layer', () async {
    const failure = ServerFailure('deletion failed');
    final repository = _FakeHomeRepository(const Left(failure));

    final result = await DeleteAccount(repository)();

    expect(result, const Left<Failure, void>(failure));
    expect(repository.deleteCalls, 1);
  });
}

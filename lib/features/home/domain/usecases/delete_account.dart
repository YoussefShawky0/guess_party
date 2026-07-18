import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';

class DeleteAccount {
  final HomeRepository repository;

  DeleteAccount(this.repository);

  Future<Either<Failure, void>> call() async {
    return repository.deleteAccount();
  }
}

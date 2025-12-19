import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';
import 'package:guess_party/features/home/domain/repositories/home_repository.dart';

class GetCurrentUser {
  final HomeRepository repository;

  GetCurrentUser(this.repository);

  Future<Either<Failure, UserInfo>> call() async {
    return await repository.getCurrentUser();
  }
}

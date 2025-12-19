import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/features/home/domain/entities/user_info.dart';

abstract class HomeRepository {
  Future<Either<Failure, UserInfo>> getCurrentUser();
  Future<Either<Failure, void>> signOut();
}

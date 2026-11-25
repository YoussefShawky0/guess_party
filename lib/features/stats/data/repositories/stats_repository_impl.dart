import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/stats/data/datasources/stats_remote_data_source.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';

class StatsRepositoryImpl implements StatsRepository {
  final StatsRemoteDataSource remoteDataSource;

  StatsRepositoryImpl({required this.remoteDataSource});

  @override
  ResultFuture<PlayerStats> getMyStats() async {
    try {
      return Right(await remoteDataSource.getMyStats());
    } catch (e) {
      return Left(ServerFailure.from(e));
    }
  }
}

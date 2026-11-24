import 'package:dartz/dartz.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/core/error/failures.dart';
import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/stats/domain/badges.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';
import 'package:guess_party/features/stats/domain/repositories/stats_repository.dart';
import 'package:guess_party/features/stats/domain/seen_badges_store.dart';

class FakeStatsRepository implements StatsRepository {
  FakeStatsRepository(this.result);

  Either<Failure, PlayerStats> result;
  int calls = 0;

  @override
  ResultFuture<PlayerStats> getMyStats() async {
    calls++;
    return result;
  }
}

class FakeSeenBadgesStore implements SeenBadgesStore {
  FakeSeenBadgesStore([Set<BadgeId> initial = const {}]) : seen = {...initial};

  Set<BadgeId> seen;
  int writes = 0;

  @override
  Future<Set<BadgeId>> read() async => {...seen};

  @override
  Future<void> write(Set<BadgeId> value) async {
    writes++;
    seen = {...value};
  }
}

const Either<Failure, PlayerStats> statsFailure = Left(
  ServerFailure('boom', code: AppErrorCode.network),
);

const statsOneGame = PlayerStats(
  gamesPlayed: 1,
  gamesWon: 0,
  roundsPlayed: 3,
  roundsAsImposter: 1,
  imposterEscapes: 0,
  correctVotes: 2,
);

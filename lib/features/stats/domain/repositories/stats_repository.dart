import 'package:guess_party/core/utils/typedef.dart';
import 'package:guess_party/features/stats/domain/entities/player_stats.dart';

abstract class StatsRepository {
  ResultFuture<PlayerStats> getMyStats();
}

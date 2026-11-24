import 'package:guess_party/features/stats/data/models/player_stats_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class StatsRemoteDataSource {
  Future<PlayerStatsModel> getMyStats();
}

class StatsRemoteDataSourceImpl implements StatsRemoteDataSource {
  final SupabaseClient client;

  StatsRemoteDataSourceImpl({required this.client});

  @override
  Future<PlayerStatsModel> getMyStats() async {
    final response = await client.rpc('get_my_stats');
    return PlayerStatsModel.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }
}

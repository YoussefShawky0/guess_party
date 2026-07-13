import 'package:guess_party/core/services/server_clock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseServerClock implements ServerClock {
  final SupabaseClient client;

  const SupabaseServerClock(this.client);

  @override
  Future<DateTime> getServerTime() async {
    final response = await client.rpc('get_server_time').select().single();
    return DateTime.parse(response['server_time'] as String).toUtc();
  }
}

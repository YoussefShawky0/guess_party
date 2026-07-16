import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class RoomQueryService {
  Future<String?> getRoomStatus(String roomId);
  Future<Map<String, String>> getActiveCategories();
}

class SupabaseRoomQueryService implements RoomQueryService {
  SupabaseRoomQueryService(this._client);

  final SupabaseClient _client;

  @override
  Future<String?> getRoomStatus(String roomId) async {
    final room = await _client
        .from('rooms')
        .select('status')
        .eq('id', roomId)
        .maybeSingle();
    return room?['status'] as String?;
  }

  @override
  Future<Map<String, String>> getActiveCategories() async {
    final rows = await _client
        .from('categories')
        .select('key, name')
        .eq('is_active', true)
        .order('sort_order', ascending: true);
    return <String, String>{
      for (final row in rows) row['key'] as String: row['name'] as String,
    };
  }
}

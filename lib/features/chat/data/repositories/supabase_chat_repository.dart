import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient client;

  const SupabaseChatRepository(this.client);

  @override
  Future<List<Map<String, dynamic>>> getMessages({
    required String roomId,
    required String roundId,
  }) async {
    final response = await client
        .from('messages')
        .select('*, players!inner(username)')
        .eq('room_id', roomId)
        .eq('round_id', roundId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchMessages({
    required String roomId,
    required String roundId,
  }) {
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('round_id', roundId)
        .asyncMap((_) => getMessages(roomId: roomId, roundId: roundId));
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String roundId,
    required String playerId,
    required String content,
  }) async {
    await client.from('messages').insert({
      'room_id': roomId,
      'round_id': roundId,
      'player_id': playerId,
      'content': content,
    });
  }
}

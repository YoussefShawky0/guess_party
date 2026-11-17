import 'package:guess_party/features/auth/data/models/player_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single implementation of "watch the players of a room", shared by the game
/// and room features so every screen agrees on player order (and therefore on
/// who the "oldest" member is).
///
/// Ordering matches the server's host-migration pick
/// (`order by p.created_at asc, p.id asc`, see
/// `public.reconcile_room_after_presence_change` in supabase/migrations):
/// oldest first, `id`
/// as the tiebreak. Rows without a `created_at` sort first.
Stream<List<PlayerModel>> watchRoomPlayersStream(
  SupabaseClient client, {
  required String roomId,
  bool onlineOnly = false,
}) {
  return client
      .from('players')
      .stream(primaryKey: ['id'])
      .eq('room_id', roomId)
      .map(
        (rows) => playersFromRows(
          rows.cast<Map<String, dynamic>>(),
          onlineOnly: onlineOnly,
        ),
      );
}

/// Pure row -> ordered players mapping used by [watchRoomPlayersStream].
List<PlayerModel> playersFromRows(
  Iterable<Map<String, dynamic>> rows, {
  bool onlineOnly = false,
}) {
  final players = rows
      .where((row) => !onlineOnly || row['is_online'] == true)
      .map(PlayerModel.fromJson)
      .toList();
  sortPlayersOldestFirst(players);
  return List<PlayerModel>.unmodifiable(players);
}

/// Sorts in place by `createdAt` ascending (nulls first), then `id`.
void sortPlayersOldestFirst(List<PlayerModel> players) {
  players.sort((a, b) {
    final aTime = a.createdAt;
    final bTime = b.createdAt;
    if (aTime == null && bTime == null) return a.id.compareTo(b.id);
    if (aTime == null) return -1;
    if (bTime == null) return 1;
    final compared = aTime.compareTo(bTime);
    return compared == 0 ? a.id.compareTo(b.id) : compared;
  });
}

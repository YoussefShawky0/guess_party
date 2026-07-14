import 'dart:async';

import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/entities/chat_page.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient client;

  const SupabaseChatRepository(this.client);

  @override
  Future<ChatPage> getMessages({
    required String roomId,
    required String roundId,
    ChatCursor? before,
    int limit = 30,
  }) async {
    final response = await client.rpc(
      'list_chat_messages',
      params: {
        'p_room_id': roomId,
        'p_round_id': roundId,
        'p_before_created_at': before?.createdAt.toUtc().toIso8601String(),
        'p_before_id': before?.id,
        'p_limit': limit,
      },
    );
    final messages = (response as List<dynamic>)
        .map((row) => _messageFromMap(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
    final nextCursor = messages.length >= limit
        ? ChatCursor(createdAt: messages.last.createdAt, id: messages.last.id)
        : null;

    return ChatPage(messages: messages, nextCursor: nextCursor);
  }

  @override
  Stream<ChatMessage> watchNewMessages({
    required String roomId,
    required String roundId,
  }) {
    late final StreamController<ChatMessage> controller;
    RealtimeChannel? channel;

    controller = StreamController<ChatMessage>(
      onListen: () {
        final realtimeChannel = client.channel('chat_messages_$roundId');
        realtimeChannel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'round_id',
            value: roundId,
          ),
          callback: (payload) {
            unawaited(
              _emitInsertedMessage(
                payload.newRecord,
                roomId,
                roundId,
                controller,
              ),
            );
          },
        );
        realtimeChannel.subscribe((status, error) {
          if (error != null && !controller.isClosed) {
            controller.addError(error);
          }
        });
        channel = realtimeChannel;
      },
      onCancel: () async {
        final activeChannel = channel;
        channel = null;
        if (activeChannel != null) {
          await activeChannel.unsubscribe();
        }
      },
    );

    return controller.stream;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String roundId,
    required String content,
  }) async {
    final response = await client.rpc(
      'send_chat_message',
      params: {
        'p_room_id': roomId,
        'p_round_id': roundId,
        'p_content': content,
      },
    );
    return _messageFromMap(Map<String, dynamic>.from(response as Map));
  }

  @override
  Future<void> setMuted({
    required String roomId,
    required String playerId,
    required bool muted,
  }) async {
    await client.rpc(
      'set_player_muted',
      params: {
        'p_room_id': roomId,
        'p_muted_player_id': playerId,
        'p_muted': muted,
      },
    );
  }

  @override
  Future<void> reportMessage({
    required String messageId,
    required String reason,
  }) async {
    await client.rpc(
      'report_chat_message',
      params: {'p_message_id': messageId, 'p_reason': reason},
    );
  }

  Future<void> _emitInsertedMessage(
    Map<String, dynamic> row,
    String roomId,
    String roundId,
    StreamController<ChatMessage> controller,
  ) async {
    try {
      if (row['room_id']?.toString() != roomId ||
          row['round_id']?.toString() != roundId) {
        return;
      }
      final playerId = row['player_id']?.toString();
      final username = await _usernameForPlayer(playerId);
      if (!controller.isClosed) {
        controller.add(
          _messageFromMap({...row, 'username': username ?? 'Player'}),
        );
      }
    } catch (error, stackTrace) {
      if (!controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    }
  }

  Future<String?> _usernameForPlayer(String? playerId) async {
    if (playerId == null || playerId.isEmpty) return null;
    final response = await client
        .from('players')
        .select('username')
        .eq('id', playerId)
        .maybeSingle();
    return response?['username']?.toString();
  }

  ChatMessage _messageFromMap(Map<String, dynamic> map) {
    final playerJoin = map['players'];
    final username =
        map['username']?.toString() ??
        (playerJoin is Map<String, dynamic>
            ? playerJoin['username']?.toString()
            : null) ??
        'Player';
    return ChatMessage(
      id: map['id'].toString(),
      roomId: map['room_id'].toString(),
      roundId: map['round_id'].toString(),
      playerId: map['player_id'].toString(),
      username: username,
      content: map['content']?.toString() ?? '',
      createdAt: DateTime.parse(map['created_at'].toString()).toUtc(),
    );
  }
}

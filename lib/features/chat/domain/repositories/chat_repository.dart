import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/entities/chat_page.dart';

abstract interface class ChatRepository {
  Future<ChatPage> getMessages({
    required String roomId,
    required String roundId,
    ChatCursor? before,
    int limit = 30,
  });

  Stream<ChatMessage> watchNewMessages({
    required String roomId,
    required String roundId,
  });

  Future<ChatMessage> sendMessage({
    required String roomId,
    required String roundId,
    required String content,
  });

  Future<void> setMuted({
    required String roomId,
    required String playerId,
    required bool muted,
  });

  Future<void> reportMessage({
    required String messageId,
    required String reason,
  });
}

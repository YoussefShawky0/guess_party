import 'package:equatable/equatable.dart';
import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';

class ChatPage extends Equatable {
  const ChatPage({required this.messages, required this.nextCursor});

  final List<ChatMessage> messages;
  final ChatCursor? nextCursor;

  @override
  List<Object?> get props => [messages, nextCursor];
}

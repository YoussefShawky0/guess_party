import 'package:equatable/equatable.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  const ChatLoaded({
    required this.messages,
    required this.mutedPlayerIds,
    this.nextCursor,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.messageCode,
  });

  final List<ChatMessage> messages;
  final Set<String> mutedPlayerIds;
  final ChatCursor? nextCursor;
  final bool isLoadingOlder;
  final bool isSending;

  /// Transient notice or error for the view to localize and show once.
  final AppErrorCode? messageCode;

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    Set<String>? mutedPlayerIds,
    ChatCursor? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingOlder,
    bool? isSending,
    AppErrorCode? messageCode,
    bool clearErrorMessage = false,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      mutedPlayerIds: mutedPlayerIds ?? this.mutedPlayerIds,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      messageCode: clearErrorMessage ? null : messageCode ?? this.messageCode,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    mutedPlayerIds,
    nextCursor,
    isLoadingOlder,
    isSending,
    messageCode,
  ];
}

class ChatFailure extends ChatState {
  const ChatFailure(this.code);

  final AppErrorCode code;

  @override
  List<Object> get props => [code];
}

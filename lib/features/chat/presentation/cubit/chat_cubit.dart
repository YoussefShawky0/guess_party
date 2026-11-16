import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:guess_party/core/error/app_error_code.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/features/chat/presentation/cubit/chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository) : super(const ChatInitial());

  final ChatRepository _repository;
  StreamSubscription<ChatMessage>? _subscription;
  String? _roomId;
  String? _roundId;

  Future<void> start({required String roomId, required String roundId}) async {
    _roomId = roomId;
    _roundId = roundId;
    if (isClosed) return;
    emit(const ChatLoading());
    await _subscription?.cancel();
    if (isClosed) return;
    try {
      final page = await _repository.getMessages(
        roomId: roomId,
        roundId: roundId,
      );
      if (isClosed) return;
      emit(
        ChatLoaded(
          messages: _sortAscending(page.messages),
          mutedPlayerIds: const {},
          nextCursor: page.nextCursor,
        ),
      );
      _subscription = _repository
          .watchNewMessages(roomId: roomId, roundId: roundId)
          .listen(_handleRealtimeMessage, onError: _handleStreamError);
    } catch (_) {
      if (isClosed) return;
      emit(const ChatFailure(AppErrorCode.chatLoadFailed));
    }
  }

  Future<void> loadOlder() async {
    final current = state;
    final roomId = _roomId;
    final roundId = _roundId;
    if (current is! ChatLoaded ||
        current.isLoadingOlder ||
        current.nextCursor == null ||
        roomId == null ||
        roundId == null) {
      return;
    }

    emit(current.copyWith(isLoadingOlder: true, clearErrorMessage: true));
    try {
      final page = await _repository.getMessages(
        roomId: roomId,
        roundId: roundId,
        before: current.nextCursor,
      );
      if (isClosed) return;
      emit(
        current.copyWith(
          messages: _mergeMessages(current.messages, page.messages),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingOlder: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        current.copyWith(
          isLoadingOlder: false,
          messageCode: AppErrorCode.chatLoadOlderFailed,
        ),
      );
    }
  }

  Future<void> send(String content) async {
    final current = state;
    final roomId = _roomId;
    final roundId = _roundId;
    final trimmed = content.trim();
    if (current is! ChatLoaded ||
        current.isSending ||
        trimmed.isEmpty ||
        roomId == null ||
        roundId == null) {
      return;
    }
    if (trimmed.length > 500) {
      emit(current.copyWith(messageCode: AppErrorCode.invalidChatContent));
      return;
    }

    emit(current.copyWith(isSending: true, clearErrorMessage: true));
    try {
      final message = await _repository.sendMessage(
        roomId: roomId,
        roundId: roundId,
        content: trimmed,
      );
      if (isClosed) return;
      final latest = state;
      if (latest is ChatLoaded) {
        emit(
          latest.copyWith(
            messages: _mergeMessages(latest.messages, [message]),
            isSending: false,
          ),
        );
      }
    } catch (error) {
      if (isClosed) return;
      final latest = state;
      if (latest is ChatLoaded) {
        emit(
          latest.copyWith(isSending: false, messageCode: _sendErrorCode(error)),
        );
      }
    }
  }

  Future<void> setMuted({required String playerId, required bool muted}) async {
    final current = state;
    final roomId = _roomId;
    if (current is! ChatLoaded || roomId == null) return;

    try {
      await _repository.setMuted(
        roomId: roomId,
        playerId: playerId,
        muted: muted,
      );
      if (isClosed) return;
      final mutedIds = {...current.mutedPlayerIds};
      if (muted) {
        mutedIds.add(playerId);
      } else {
        mutedIds.remove(playerId);
      }
      emit(
        current.copyWith(
          mutedPlayerIds: mutedIds,
          messages: muted
              ? current.messages
                    .where((message) => message.playerId != playerId)
                    .toList(growable: false)
              : current.messages,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(messageCode: AppErrorCode.chatMuteFailed));
    }
  }

  Future<void> report({
    required String messageId,
    required String reason,
  }) async {
    final current = state;
    final trimmed = reason.trim();
    if (current is! ChatLoaded || trimmed.isEmpty) return;

    try {
      await _repository.reportMessage(messageId: messageId, reason: trimmed);
      if (isClosed) return;
      emit(current.copyWith(messageCode: AppErrorCode.reportSubmitted));
    } catch (_) {
      if (isClosed) return;
      emit(current.copyWith(messageCode: AppErrorCode.reportFailed));
    }
  }

  void acknowledgeMessage() {
    final current = state;
    if (current is ChatLoaded && current.messageCode != null) {
      emit(current.copyWith(clearErrorMessage: true));
    }
  }

  void _handleRealtimeMessage(ChatMessage message) {
    final current = state;
    if (current is! ChatLoaded ||
        current.mutedPlayerIds.contains(message.playerId)) {
      return;
    }
    emit(
      current.copyWith(
        messages: _mergeMessages(current.messages, [message]),
        clearErrorMessage: true,
      ),
    );
  }

  void _handleStreamError(Object _) {
    final current = state;
    if (current is ChatLoaded) {
      emit(
        current.copyWith(messageCode: AppErrorCode.chatConnectionInterrupted),
      );
    }
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> existing,
    List<ChatMessage> incoming,
  ) {
    final byId = <String, ChatMessage>{
      for (final message in existing) message.id: message,
    };
    for (final message in incoming) {
      byId[message.id] = message;
    }
    return _sortAscending(byId.values);
  }

  List<ChatMessage> _sortAscending(Iterable<ChatMessage> messages) {
    final sorted = messages.toList(growable: false);
    sorted.sort((a, b) {
      final byCreatedAt = a.createdAt.compareTo(b.createdAt);
      if (byCreatedAt != 0) return byCreatedAt;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  AppErrorCode _sendErrorCode(Object error) {
    final code = appErrorCodeFrom(error);
    return code == AppErrorCode.chatRateLimited ||
            code == AppErrorCode.invalidChatContent
        ? code
        : AppErrorCode.chatSendFailed;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

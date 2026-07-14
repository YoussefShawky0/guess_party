import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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
    emit(const ChatLoading());
    await _subscription?.cancel();
    try {
      final page = await _repository.getMessages(
        roomId: roomId,
        roundId: roundId,
      );
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
      emit(const ChatFailure('Unable to load chat. Please try again.'));
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
      emit(
        current.copyWith(
          messages: _mergeMessages(current.messages, page.messages),
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoadingOlder: false,
        ),
      );
    } catch (_) {
      emit(
        current.copyWith(
          isLoadingOlder: false,
          errorMessage: 'Unable to load older messages.',
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
      emit(
        current.copyWith(
          errorMessage: 'Message must be 500 characters or less.',
        ),
      );
      return;
    }

    emit(current.copyWith(isSending: true, clearErrorMessage: true));
    try {
      final message = await _repository.sendMessage(
        roomId: roomId,
        roundId: roundId,
        content: trimmed,
      );
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
      final latest = state;
      if (latest is ChatLoaded) {
        emit(
          latest.copyWith(
            isSending: false,
            errorMessage: _friendlySendError(error),
          ),
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
      emit(current.copyWith(errorMessage: 'Unable to update mute setting.'));
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
      emit(current.copyWith(errorMessage: 'Report submitted for review.'));
    } catch (_) {
      emit(current.copyWith(errorMessage: 'Unable to submit report.'));
    }
  }

  void acknowledgeMessage() {
    final current = state;
    if (current is ChatLoaded && current.errorMessage != null) {
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
      emit(current.copyWith(errorMessage: 'Chat connection interrupted.'));
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

  String _friendlySendError(Object error) {
    final text = error.toString();
    if (text.contains('CHAT_RATE_LIMITED')) {
      return 'Slow down a little before sending another message.';
    }
    if (text.contains('INVALID_CHAT_CONTENT')) {
      return 'Message must be 500 characters or less.';
    }
    return 'Unable to send message. Please try again.';
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

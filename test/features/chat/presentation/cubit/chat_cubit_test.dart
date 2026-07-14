import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/entities/chat_page.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/features/chat/presentation/cubit/chat_cubit.dart';
import 'package:guess_party/features/chat/presentation/cubit/chat_state.dart';

void main() {
  test('first page is bounded and starts one message stream', () async {
    final repository = FakeChatRepository(
      pages: [
        ChatPage(
          messages: [message('m1', createdAt: DateTime.utc(2026))],
          nextCursor: ChatCursor(createdAt: DateTime.utc(2026), id: 'm1'),
        ),
      ],
    );
    final cubit = ChatCubit(repository);

    await cubit.start(roomId: 'room-1', roundId: 'round-1');

    final state = cubit.state as ChatLoaded;
    expect(repository.requestedLimits, [30]);
    expect(repository.watchCount, 1);
    expect(state.messages.map((m) => m.id), ['m1']);
    expect(state.nextCursor?.id, 'm1');
    await cubit.close();
  });

  test('older pages merge without duplicating existing messages', () async {
    final repository = FakeChatRepository(
      pages: [
        ChatPage(
          messages: [message('m2', createdAt: DateTime.utc(2026, 1, 2))],
          nextCursor: ChatCursor(createdAt: DateTime.utc(2026, 1, 2), id: 'm2'),
        ),
        ChatPage(
          messages: [
            message('m1', createdAt: DateTime.utc(2026, 1, 1)),
            message('m2', createdAt: DateTime.utc(2026, 1, 2)),
          ],
          nextCursor: null,
        ),
      ],
    );
    final cubit = ChatCubit(repository);

    await cubit.start(roomId: 'room-1', roundId: 'round-1');
    await cubit.loadOlder();

    final state = cubit.state as ChatLoaded;
    expect(state.messages.map((m) => m.id), ['m1', 'm2']);
    expect(state.nextCursor, isNull);
    expect(repository.requestedCursors.last?.id, 'm2');
    await cubit.close();
  });

  test(
    'repeated realtime inserts update by id instead of duplicating',
    () async {
      final realtime = StreamController<ChatMessage>();
      final repository = FakeChatRepository(
        pages: const [ChatPage(messages: [], nextCursor: null)],
        realtime: realtime,
      );
      final cubit = ChatCubit(repository);
      await cubit.start(roomId: 'room-1', roundId: 'round-1');

      realtime.add(message('m1', content: 'first'));
      await pumpEventQueue();
      realtime.add(message('m1', content: 'edited by stream'));
      await pumpEventQueue();

      final state = cubit.state as ChatLoaded;
      expect(state.messages, hasLength(1));
      expect(state.messages.single.content, 'edited by stream');
      await cubit.close();
      await realtime.close();
    },
  );

  test(
    'muted player messages are hidden and future events are ignored',
    () async {
      final realtime = StreamController<ChatMessage>();
      final repository = FakeChatRepository(
        pages: [
          ChatPage(
            messages: [
              message('m1', playerId: 'player-a'),
              message('m2', playerId: 'player-b'),
            ],
            nextCursor: null,
          ),
        ],
        realtime: realtime,
      );
      final cubit = ChatCubit(repository);
      await cubit.start(roomId: 'room-1', roundId: 'round-1');

      await cubit.setMuted(playerId: 'player-b', muted: true);
      realtime.add(message('m3', playerId: 'player-b'));
      await pumpEventQueue();

      final state = cubit.state as ChatLoaded;
      expect(state.messages.map((m) => m.playerId).toSet(), {'player-a'});
      expect(repository.muteCalls, ['player-b:true']);
      await cubit.close();
      await realtime.close();
    },
  );

  test('rate-limit server errors map to player-safe copy', () async {
    final repository = FakeChatRepository(
      pages: const [ChatPage(messages: [], nextCursor: null)],
      sendError: Exception('CHAT_RATE_LIMITED'),
    );
    final cubit = ChatCubit(repository);
    await cubit.start(roomId: 'room-1', roundId: 'round-1');

    await cubit.send('too fast');

    final state = cubit.state as ChatLoaded;
    expect(
      state.errorMessage,
      'Slow down a little before sending another message.',
    );
    await cubit.close();
  });

  test('closing the cubit cancels the active chat stream', () async {
    var canceled = false;
    final realtime = StreamController<ChatMessage>(
      onCancel: () {
        canceled = true;
      },
    );
    final repository = FakeChatRepository(
      pages: const [ChatPage(messages: [], nextCursor: null)],
      realtime: realtime,
    );
    final cubit = ChatCubit(repository);
    await cubit.start(roomId: 'room-1', roundId: 'round-1');

    await cubit.close();

    expect(canceled, isTrue);
    await realtime.close();
  });
}

ChatMessage message(
  String id, {
  String playerId = 'player-a',
  String content = 'hello',
  DateTime? createdAt,
}) {
  return ChatMessage(
    id: id,
    roomId: 'room-1',
    roundId: 'round-1',
    playerId: playerId,
    username: playerId,
    content: content,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  );
}

class FakeChatRepository implements ChatRepository {
  FakeChatRepository({
    required List<ChatPage> pages,
    StreamController<ChatMessage>? realtime,
    this.sendError,
  }) : _pages = QueueList(pages),
       _realtime = realtime ?? StreamController<ChatMessage>();

  final QueueList<ChatPage> _pages;
  final StreamController<ChatMessage> _realtime;
  final Object? sendError;
  final requestedLimits = <int>[];
  final requestedCursors = <ChatCursor?>[];
  final muteCalls = <String>[];
  int watchCount = 0;

  @override
  Future<ChatPage> getMessages({
    required String roomId,
    required String roundId,
    ChatCursor? before,
    int limit = 30,
  }) async {
    requestedLimits.add(limit);
    requestedCursors.add(before);
    return _pages.removeFirst();
  }

  @override
  Future<void> reportMessage({
    required String messageId,
    required String reason,
  }) async {}

  @override
  Future<ChatMessage> sendMessage({
    required String roomId,
    required String roundId,
    required String content,
  }) async {
    final error = sendError;
    if (error != null) throw error;
    return message('sent', content: content);
  }

  @override
  Future<void> setMuted({
    required String roomId,
    required String playerId,
    required bool muted,
  }) async {
    muteCalls.add('$playerId:$muted');
  }

  @override
  Stream<ChatMessage> watchNewMessages({
    required String roomId,
    required String roundId,
  }) {
    watchCount++;
    return _realtime.stream;
  }
}

class QueueList<T> {
  QueueList(Iterable<T> values) : _values = values.toList();

  final List<T> _values;

  T removeFirst() => _values.removeAt(0);
}

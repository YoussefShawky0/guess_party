import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guess_party/core/constants/app_colors.dart';
import 'package:guess_party/core/di/injection_container.dart';
import 'package:guess_party/features/chat/domain/entities/chat_cursor.dart';
import 'package:guess_party/features/chat/domain/entities/chat_message.dart';
import 'package:guess_party/features/chat/domain/entities/chat_page.dart';
import 'package:guess_party/features/chat/domain/repositories/chat_repository.dart';
import 'package:guess_party/shared/widgets/chat_widget.dart';

void main() {
  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'renders bounded chat page and sends messages through the cubit',
    (tester) async {
      final repository = WidgetFakeChatRepository(
        pages: const [ChatPage(messages: [], nextCursor: null)],
      );
      sl.registerSingleton<ChatRepository>(repository);

      await tester.pumpWidget(chatHarness());
      await tester.pumpAndSettle();

      expect(find.text('No messages yet'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'hello chat');
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(repository.sentContent, ['hello chat']);
    },
  );

  testWidgets('long-pressing another player message can mute that player', (
    tester,
  ) async {
    final repository = WidgetFakeChatRepository(
      pages: [
        ChatPage(
          messages: [
            chatMessage(
              'message-1',
              playerId: 'other-player',
              username: 'Other',
            ),
          ],
          nextCursor: null,
        ),
      ],
    );
    sl.registerSingleton<ChatRepository>(repository);

    await tester.pumpWidget(chatHarness());
    await tester.pumpAndSettle();
    await tester.longPress(find.text('hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mute this player'));
    await tester.pumpAndSettle();

    expect(repository.muteCalls, ['other-player:true']);
    expect(find.text('hello'), findsNothing);
  });
}

Widget chatHarness() {
  return MaterialApp(
    theme: ThemeData(
      extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
    ),
    home: const Scaffold(
      body: ChatWidget(
        roomId: 'room-1',
        roundId: 'round-1',
        currentPlayerId: 'current-player',
      ),
    ),
  );
}

ChatMessage chatMessage(
  String id, {
  String playerId = 'current-player',
  String username = 'Current',
}) {
  return ChatMessage(
    id: id,
    roomId: 'room-1',
    roundId: 'round-1',
    playerId: playerId,
    username: username,
    content: 'hello',
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

class WidgetFakeChatRepository implements ChatRepository {
  WidgetFakeChatRepository({required List<ChatPage> pages})
    : _pages = QueueList(pages);

  final QueueList<ChatPage> _pages;
  final sentContent = <String>[];
  final muteCalls = <String>[];
  final _stream = StreamController<ChatMessage>();

  @override
  Future<ChatPage> getMessages({
    required String roomId,
    required String roundId,
    ChatCursor? before,
    int limit = 30,
  }) async {
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
    sentContent.add(content);
    return chatMessage('sent', username: 'Current');
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
    return _stream.stream;
  }
}

class QueueList<T> {
  QueueList(Iterable<T> values) : _values = values.toList();

  final List<T> _values;

  T removeFirst() => _values.removeAt(0);
}

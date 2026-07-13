abstract interface class ChatRepository {
  Future<List<Map<String, dynamic>>> getMessages({
    required String roomId,
    required String roundId,
  });

  Stream<List<Map<String, dynamic>>> watchMessages({
    required String roomId,
    required String roundId,
  });

  Future<void> sendMessage({
    required String roomId,
    required String roundId,
    required String playerId,
    required String content,
  });
}

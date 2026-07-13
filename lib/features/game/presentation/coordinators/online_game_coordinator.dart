abstract interface class OnlineGameCoordinator {
  int get activeOnlineGameSubscriptionCount;

  Future<void> refreshGameStateOnResume({
    required String roomId,
    int maxRetries,
  });

  Future<void> setCurrentPlayerPresence({
    required String roomId,
    required String userId,
    required bool isOnline,
  });
}

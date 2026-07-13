abstract interface class RoomSessionCoordinator {
  int get activeSessionSubscriptionCount;

  Future<void> watchRoomStatus({required String roomId});
}

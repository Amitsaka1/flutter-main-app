// ── Web stub — LiveKit runs on mobile only ──────

class LiveKitService {

  bool get isConnected  => false;
  bool get isMicEnabled => false;
  dynamic get room      => null;

  // new: Fix #3
  void Function()? onReconnected;

  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {}

  Future<void> connectWithToken({
    required String token,
    required String roomId,
    required String role,
  }) async {}

  Future<void> enableMic()  async {}
  Future<void> disableMic() async {}
  Future<void> toggleMic()  async {}

  // modify: Fix #5
  Future<void> disconnect({String? expectedRoomId}) async {}

  void reset() {}
}

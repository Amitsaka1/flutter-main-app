// ── Web stub — LiveKit runs on mobile only ──────

class LiveKitService {

  bool get isConnected  => false;
  bool get isMicEnabled => false;

  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {
    // No-op on web
  }

  Future<void> enableMic()  async {}
  Future<void> disableMic() async {}
  Future<void> toggleMic()  async {}

  Future<void> disconnect() async {}

  void reset() {}
}

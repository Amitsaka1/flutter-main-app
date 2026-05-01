class LiveKitService {
  dynamic room;

  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {
    // Web pe kuch nahi karega
  }

  Future<void> enableMic() async {}

  Future<void> disableMic() async {}

  Future<void> disconnect({String? roomId}) async {}
}

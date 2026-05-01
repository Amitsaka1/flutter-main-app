class FakeRoom {
  Stream<dynamic> get events => const Stream.empty();
}

class LiveKitService {
  FakeRoom? room;

  Future<void> connect({
    required String userId,
    required String roomId,
    required String role,
  }) async {
    room = FakeRoom();
    print("❌ LiveKit disabled on Web");
  }

  Future<void> enableMic() async {}
  Future<void> disableMic() async {}
  Future<void> disconnect({String? roomId}) async {
    room = null;
  }
}

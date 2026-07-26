import '../socket/centrifugo_service.dart';

class SocketManager {
  static CentrifugoService? _instance;
  static String? _currentUserId;

  static CentrifugoService getInstance(String userId) {
    if (_instance == null || _currentUserId != userId) {
      _instance?.dispose();
      _instance = CentrifugoService(userId: userId);
      _currentUserId = userId;
    }
    return _instance!;
  }

  static Future<CentrifugoService> connect(String userId) async {
    final socket = getInstance(userId);
    if (!socket.isConnected) {
      await socket.connect();
    }
    return socket;
  }

  static void disconnect() {
    _instance?.dispose();
    _instance = null;
    _currentUserId = null;
  }

  static CentrifugoService? get instance => _instance;
}

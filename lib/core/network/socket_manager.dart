import '../socket/websocket_service.dart';

class SocketManager {
  static WebSocketService? _instance;
  static String? _currentUserId;

  // ================= GET INSTANCE =================

  static WebSocketService getInstance(String userId) {
    if (_instance == null || _currentUserId != userId) {
      _instance?.dispose();

      _instance = WebSocketService(userId: userId);
      _currentUserId = userId;
    }

    return _instance!;
  }

  // ================= CONNECT =================

  static Future<WebSocketService> connect(String userId) async {
    final socket = getInstance(userId);

    if (!socket.isConnected) {
      await socket.connect();
    }

    return socket;
  }

  // ================= DISCONNECT =================

  static void disconnect() {
    _instance?.dispose();
    _instance = null;
    _currentUserId = null;
  }

  // ================= INSTANCE GETTER =================

  static WebSocketService? get instance => _instance;
}

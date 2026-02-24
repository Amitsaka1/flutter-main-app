import 'websocket_service.dart';

class SocketManager {

  static WebSocketService? _instance;

  static WebSocketService getInstance(String userId) {
    _instance ??= WebSocketService(userId: userId);
    return _instance!;
  }

  static WebSocketService? get instance => _instance;
}

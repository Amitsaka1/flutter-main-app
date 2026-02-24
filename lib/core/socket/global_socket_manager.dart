import 'dart:async';
import 'websocket_service.dart';

class GlobalSocketManager {
  GlobalSocketManager._internal();
  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();
  static GlobalSocketManager get instance => _instance;

  WebSocketService? _socketService;

  String? _userId;
  bool _initialized = false;

  final StreamController<Map<String, dynamic>>
      _messageController = StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

  // ================= INIT =================

  Future<void> init(String userId) async {
    if (_initialized && _userId == userId) return;

    _userId = userId;

    _socketService?.dispose();

    _socketService = WebSocketService(userId: userId);

    _socketService!.messages.listen((event) {
      _messageController.add(event);
    });

    await _socketService!.connect();

    _initialized = true;
  }

  // ================= SEND =================

  void send(Map<String, dynamic> data) {
    _socketService?.send(data);
  }

  // ================= DISCONNECT =================

  void disconnect() {
    _socketService?.disconnect();
    _initialized = false;
    _userId = null;
  }

  bool get isConnected =>
      _socketService?.isConnected ?? false;

  // ================= DISPOSE =================

  void dispose() {
    _socketService?.dispose();
    _messageController.close();
  }
}

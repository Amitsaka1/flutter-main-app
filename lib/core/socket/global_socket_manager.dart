import 'dart:async';
import 'socket_service.dart';

class GlobalSocketManager {
  GlobalSocketManager._internal();
  static final GlobalSocketManager _instance =
      GlobalSocketManager._internal();
  static GlobalSocketManager get instance => _instance;

  String? _userId;
  bool _connected = false;
  bool _initializing = false;

  final StreamController<dynamic> _messageController =
      StreamController.broadcast();

  Stream<dynamic> get messages => _messageController.stream;

  // ================= INIT =================

  Future<void> init(String userId) async {
    if (_connected || _initializing) return;

    _initializing = true;
    _userId = userId;

    SocketService.connect(userId);

    SocketService.onMessage((data) {
      _messageController.add(data);
    });

    _connected = true;
    _initializing = false;
  }

  // ================= DISCONNECT =================

  void disconnect() {
    if (!_connected) return;

    SocketService.disconnect();
    _connected = false;
    _userId = null;
  }

  bool get isConnected => _connected;

  void dispose() {
    _messageController.close();
  }
}

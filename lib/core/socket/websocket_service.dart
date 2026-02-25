import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;

  WebSocket? _socket;

  bool _connected = false;
  bool _connecting = false;
  bool _manualDisconnect = false;

  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  WebSocketService({required this.userId});

  // ================= CONNECT =================

  Future<void> connect() async {
    if (_connected || _connecting) return;

    _connecting = true;
    _manualDisconnect = false;

    try {
      _socket = await WebSocket.connect(
        "wss://momo-1etm.onrender.com/ws?userId=$userId",
      );

      _connected = true;
      _connecting = false;
      _reconnectAttempt = 0;

      _socket!.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);
            _controller.add(decoded);
          } catch (_) {}
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _connecting = false;
      _scheduleReconnect();
    }
  }

  // ================= DISCONNECT =================

  void disconnect() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    _connected = false;
  }

  // ================= HANDLE DISCONNECT =================

  void _handleDisconnect() {
    _socket = null;
    _connected = false;

    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  // ================= AUTO RECONNECT =================

  void _scheduleReconnect() {
    if (_manualDisconnect) return;

    _reconnectAttempt++;

    // Exponential backoff (2s → 4s → 6s → ... max 30s)
    int delaySeconds =
        (_reconnectAttempt * 2).clamp(2, 30);

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () {
        connect();
      },
    );
  }

  // ================= SEND =================

  void send(Map<String, dynamic> data) {
    if (_connected && _socket != null) {
      _socket!.add(jsonEncode(data));
    }
  }

  // ================= STATE =================

  bool get isConnected => _connected;

  // ================= DISPOSE =================

  void dispose() {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _socket?.close();
    _socket = null;
    _connected = false;
    _controller.close();
  }
}

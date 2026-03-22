import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:app_project/core/network/api_client.dart';

class WebSocketService {
  final String userId;

  final String wsUrl = "wss://momo-1etm.onrender.com/ws";

  WebSocketChannel? _channel;

  bool _connected = false;
  bool _connecting = false;
  bool _manualDisconnect = false;

  int _reconnectAttempt = 0;

  Timer? _reconnectTimer;
  Timer? _pingTimer; // 🔥 FIXED

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;

  WebSocketService({required this.userId});

  // ================= CONNECT =================

  Future<void> connect() async {
    if (_connected || _connecting) return;

    _connecting = true;
    _manualDisconnect = false;

    try {
      print("⚡ Connecting WebSocket for user: $userId");

      final token = await ApiClient.getToken();

      _channel = WebSocketChannel.connect(
        Uri.parse("$wsUrl?token=$token"),
      );

      _connected = true;
      _connecting = false;
      _reconnectAttempt = 0;

      print("🔥 SOCKET CONNECTED for user: $userId");

      // 🔥 FIX: clear old timers
      _pingTimer?.cancel();

      _pingTimer = Timer.periodic(
        const Duration(seconds: 20),
        (_) {
          if (_connected && _channel != null) {
            try {
              _channel!.sink.add('ping');
            } catch (_) {}
          }
        },
      );

      _channel!.stream.listen(
        (data) {
          try {
            final decoded = jsonDecode(data);

            if (decoded["type"] == "NEW_NOTIFICATION") {
              _notificationController.add(decoded);
              return;
            }

            _messageController.add(decoded);
          } catch (e) {
            print("Socket decode error: $e");
          }
        },
        onDone: _handleDisconnect,
        onError: (error) {
          print("Socket error: $error");
          _handleDisconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      print("❌ WebSocket connection failed: $e");
      _connecting = false;
      _scheduleReconnect();
    }
  }

  // ================= DISCONNECT =================

  void disconnect() {
    print("🔴 Manual disconnect for user: $userId");

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel(); // 🔥 FIX

    _channel?.sink.close();
    _channel = null;

    _connected = false;
  }

  // ================= HANDLE DISCONNECT =================

  void _handleDisconnect() {
    print("❌ SOCKET DISCONNECTED for user: $userId");

    _channel = null;
    _connected = false;

    _pingTimer?.cancel(); // 🔥 FIX

    if (!_manualDisconnect) {
      _scheduleReconnect();
    }
  }

  // ================= AUTO RECONNECT =================

  void _scheduleReconnect() {
    if (_manualDisconnect) return;

    _reconnectAttempt++;

    int delaySeconds =
        (_reconnectAttempt * 2).clamp(2, 30);

    print(
        "⏳ Reconnecting in $delaySeconds sec (Attempt $_reconnectAttempt)");

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
    if (_connected && _channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (e) {
        print("Send error: $e");
      }
    } else {
      print("⚠ Cannot send. Socket not connected.");
    }
  }

  // ================= STATE =================

  bool get isConnected => _connected;

  // ================= DISPOSE =================

  void dispose() {
    print("🧹 Disposing WebSocket for user: $userId");

    _manualDisconnect = true;

    _reconnectTimer?.cancel();
    _pingTimer?.cancel(); // 🔥 FIX

    _channel?.sink.close();
    _channel = null;

    _connected = false;

    _messageController.close();
    _notificationController.close();
  }
}

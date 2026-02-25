import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;

  WebSocket? _socket;

  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  int _unreadNotifications = 0;

  bool _isConnecting = false;
  bool _manuallyDisconnected = false;

  Stream<Map<String, dynamic>> get messages =>
      _messageController.stream;

  Stream<Map<String, dynamic>> get notifications =>
      _notificationController.stream;

  int get unreadNotifications => _unreadNotifications;

  bool get isConnected => _socket != null;

  WebSocketService({required this.userId});

  // ================= CONNECT =================

  Future<void> connect() async {
    if (_socket != null || _isConnecting) return;

    _isConnecting = true;
    _manuallyDisconnected = false;

    try {
      _socket = await WebSocket.connect(
        "wss://momo-1etm.onrender.com?userId=$userId",
      );

      _socket!.listen(
        _onMessage,
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _handleReconnect();
    }

    _isConnecting = false;
  }

  // ================= MESSAGE =================

  void _onMessage(dynamic data) {
    final decoded = jsonDecode(data);
    final type = decoded["type"];

    if (type == "NEW_NOTIFICATION") {
      _unreadNotifications++;
      _notificationController.add(decoded);
      return;
    }

    _messageController.add(decoded);
  }

  // ================= RECONNECT =================

  void _handleDisconnect() {
    _socket = null;

    if (!_manuallyDisconnected) {
      _handleReconnect();
    }
  }

  void _handleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!_manuallyDisconnected) {
        connect();
      }
    });
  }

  // ================= NOTIFICATION =================

  void clearNotifications() {
    _unreadNotifications = 0;
  }

  // ================= DISCONNECT =================

  void disconnect() {
    _manuallyDisconnected = true;
    _socket?.close();
    _socket = null;
  }

  // ================= DISPOSE =================

  void dispose() {
    _manuallyDisconnected = true;
    _socket?.close();
    _socket = null;

    _messageController.close();
    _notificationController.close();
  }
}

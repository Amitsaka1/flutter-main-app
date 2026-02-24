import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;

  WebSocket? _socket;

  final _messageController = StreamController.broadcast();
  final _notificationController = StreamController.broadcast();

  int _unreadNotifications = 0;

  Stream get messages => _messageController.stream;
  Stream get notifications => _notificationController.stream;

  int get unreadNotifications => _unreadNotifications;

  WebSocketService({required this.userId});

  Future<void> connect() async {
    _socket = await WebSocket.connect(
      "wss://momo-1etm.onrender.com?userId=$userId",
    );

    _socket!.listen((data) {
      final decoded = jsonDecode(data);

      final type = decoded["type"];

      // 🔥 Handle Follow Notification
      if (type == "NEW_NOTIFICATION") {
        _unreadNotifications++;
        _notificationController.add(decoded);
        return;
      }

      // 🔥 Normal message flow
      _messageController.add(decoded);
    });
  }

  void clearNotifications() {
    _unreadNotifications = 0;
  }

  void dispose() {
    _socket?.close();
    _messageController.close();
    _notificationController.close();
  }
}

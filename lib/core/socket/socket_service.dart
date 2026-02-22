import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SocketService {
  static WebSocket? _socket;
  static Function(dynamic)? _onMessage;

  static Future<void> connect(String userId) async {
    _socket = await WebSocket.connect(
        "wss://momo-1etm.onrender.com?userId=$userId");

    _socket!.listen((data) {
      if (_onMessage != null) {
        _onMessage!(jsonDecode(data));
      }
    });
  }

  static void onMessage(Function(dynamic) callback) {
    _onMessage = callback;
  }

  static void disconnect() {
    _socket?.close();
  }
}

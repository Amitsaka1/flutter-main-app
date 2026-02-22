import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;
  WebSocket? _socket;
  final _controller = StreamController.broadcast();

  Stream get messages => _controller.stream;

  WebSocketService({required this.userId});

  Future<void> connect() async {
    _socket = await WebSocket.connect(
        "wss://momo-1etm.onrender.com?userId=$userId");

    _socket!.listen((data) {
      _controller.add(jsonDecode(data));
    });
  }

  void dispose() {
    _socket?.close();
    _controller.close();
  }
}

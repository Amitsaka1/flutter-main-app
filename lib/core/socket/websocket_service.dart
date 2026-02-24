import 'dart:async';
import 'dart:convert';
import 'dart:io';

class WebSocketService {
  final String userId;
  WebSocket? _socket;

  final StreamController<Map<String, dynamic>> _controller =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  WebSocketService({required this.userId});

  Future<void> connect() async {
    _socket = await WebSocket.connect(
        "wss://momo-1etm.onrender.com/ws?userId=$userId");

    _socket!.listen(
      (data) {
        final decoded = jsonDecode(data);
        _controller.add(decoded);
      },
      onDone: () {
        _socket = null;
      },
      onError: (_) {
        _socket = null;
      },
    );
  }

  void dispose() {
    _socket?.close();
    _controller.close();
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_service.dart';
import '../../../shared/layout/app_layout.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

  List<dynamic> chats = [];
  bool loading = true;
  int totalUnread = 0;

  WebSocketService? _socket;
  StreamSubscription? _socketSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    await _fetchChats();
    _initSocket(token);
  }

  // =========================
  // FETCH RECENT CHATS
  // =========================
  Future<void> _fetchChats() async {
    try {
      final response = await ApiClient.get("/chat/recent");

      if (response["success"] == true) {
        final data = response["data"] as List;

        int unread = 0;
        for (var chat in data) {
          unread += (chat["unreadCount"] ?? 0) as int;
        }

        if (!mounted) return;

        setState(() {
          chats = data;
          totalUnread = unread;
          loading = false;
        });
      }

    } catch (e) {
      debugPrint("Chat fetch error: $e");
      setState(() => loading = false);
    }
  }

  // =========================
  // WEBSOCKET
  // =========================
  void _initSocket(String token) async {

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(token.split(".")[1])))
    );

    final myId = payload["id"];

    _socket = WebSocketService(userId: myId);
    await _socket!.connect();

    _socketSub = _socket!.messages.listen(_handleSocketMessage);
  }

  void _handleSocketMessage(dynamic message) {

    final type = message["type"];

    if (type == "NEW_MESSAGE") {
      final msg = message["data"];

      if (msg["receiverId"] == _socket!.userId) {

        setState(() {
          for (var chat in chats) {
            if (chat["user"]["id"] == msg["senderId"]) {
              chat["lastMessage"] =
                  msg["type"] == "image"
                      ? "📷 Image"
                      : msg["content"];
              chat["unreadCount"] =
                  (chat["unreadCount"] ?? 0) + 1;
            }
          }

          totalUnread++;
        });
      }
    }

    if (type == "MESSAGES_READ") {
      final senderId = message["by"];

      setState(() {
        for (var chat in chats) {
          if (chat["user"]["id"] == senderId) {
            chat["unreadCount"] = 0;
          }
        }

        totalUnread = chats.fold(
          0,
          (sum, c) => sum + (c["unreadCount"] ?? 0) as int
        );
      });
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================
@override
Widget build(BuildContext context) {

  if (loading) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: chats.length,
    itemBuilder: (context, index) {
      final chat = chats[index];

      return _ChatCard(
        chat: chat,
        onTap: () =>
            context.go("/chat/${chat["user"]["id"]}"),
      );
    },
  );
}

// =============================
// CHAT CARD
// =============================
class _ChatCard extends StatelessWidget {

  final dynamic chat;
  final VoidCallback onTap;

  const _ChatCard({
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final unread = chat["unreadCount"] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0f0f0f),
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              blurRadius: 15,
              color: Colors.black54,
            )
          ],
        ),
        child: Row(
          children: [

            Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF00F5A0),
                    Color(0xFFFF00C8),
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  chat["user"]["phone"]
                      .toString()
                      .substring(
                        chat["user"]["phone"].length - 2
                      ),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        chat["user"]["phone"],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F5A0),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            "$unread",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat["lastMessage"] ?? "",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

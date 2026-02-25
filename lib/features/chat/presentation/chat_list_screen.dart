import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with AutomaticKeepAliveClientMixin {

  final ChatController _controller = ChatController.instance;

  StreamSubscription? _subscription;

  List<dynamic> chats = [];
  bool loading = true;

  @override
  bool get wantKeepAlive => true;

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

    if (_controller.hasData) {
      setState(() {
        chats = _controller.chats;
        loading = false;
      });
    }

    _subscription = _controller.chatStream.listen((data) {
      if (!mounted) return;

      setState(() {
        chats = data;
        loading = false;
      });
    });

    _controller.loadChats();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (loading && chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];

        return ChatCard(
          chat: chat,
          onTap: () {
            final userId = chat["user"]["id"];

            // 🔥 NO await loadMessages here
            context.push("/chat/$userId");
          },
        );
      },
    );
  }
}

class ChatCard extends StatelessWidget {
  final dynamic chat;
  final VoidCallback onTap;

  const ChatCard({
    super.key,
    required this.chat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final unread = chat["unreadCount"] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [

            CircleAvatar(
              child: Text(
                chat["user"]["phone"]
                    .toString()
                    .substring(
                      chat["user"]["phone"].length - 2),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    chat["user"]["phone"],
                    style: const TextStyle(
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    chat["lastMessage"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (unread > 0)
              CircleAvatar(
                radius: 12,
                backgroundColor: Colors.green,
                child: Text(
                  "$unread",
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

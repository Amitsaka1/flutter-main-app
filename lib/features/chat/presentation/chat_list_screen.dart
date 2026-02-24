import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/cache/chat_cache.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<dynamic> chats = [];
  bool loading = true;
  int totalUnread = 0;

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

    // 🔥 Use cache instantly
    if (ChatCache.hasCache && ChatCache.isFresh) {
      final cached = ChatCache.chats!;

      int unread = 0;
      for (var chat in cached) {
        unread += (chat["unreadCount"] ?? 0) as int;
      }

      setState(() {
        chats = cached;
        totalUnread = unread;
        loading = false;
      });

      // background refresh
      _fetchChats();
    } else {
      await _fetchChats();
    }
  }

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

        // 🔥 Save to memory cache
        ChatCache.save(data);
      }
    } catch (e) {
      debugPrint("Chat fetch error: $e");
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF001F1F),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [

          // ================= HEADER =================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: const [
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              color: Colors.pinkAccent),
                          SizedBox(width: 8),
                          Text(
                            "Messages",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.search,
                              color: Colors.white70),
                          SizedBox(width: 20),
                          Icon(Icons.notifications_none,
                              color: Colors.white70),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ================= CHAT LIST =================
          Expanded(
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : chats.isEmpty
                    ? const Center(
                        child: Text(
                          "No chats yet",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chat = chats[index];

                          return _ChatCard(
                            chat: chat,
                            onTap: () =>
                                context.go("/chat/${chat["user"]["id"]}"),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

// =============================
// MODERN CHAT CARD
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
        margin: const EdgeInsets.only(bottom: 18),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF111111),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 25,
              color: Colors.black54,
              offset: Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [

            Container(
              width: 55,
              height: 55,
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
                        chat["user"]["phone"].length - 2),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                  Text(
                    chat["user"]["phone"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    chat["lastMessage"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            if (unread > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF00F5A0),
                      Color(0xFF00C9A7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$unread",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

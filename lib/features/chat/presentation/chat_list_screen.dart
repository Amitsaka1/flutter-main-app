import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_project/providers/recent_chats_provider.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState
    extends ConsumerState<ChatListScreen>
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

    // 🔥 ALWAYS LISTEN FIRST (IMPORTANT)
    _subscription = _controller.chatStream.listen((data) {
      if (!mounted) return;

      setState(() {
        chats = data;
        loading = false;
      });
    });

    // 🔥 INSTANT CACHE SHOW
    if (_controller.hasData) {

      final cachedChats =
          List<dynamic>.from(_controller.chats);

      /// 🔥 PROVIDER SYNC
      WidgetsBinding.instance
          .addPostFrameCallback((_) {

        ref
            .read(recentChatsProvider.notifier)
            .state = cachedChats;
      });

      setState(() {
        chats = cachedChats;
        loading = false;
      });
    }

    // 🔥 ALWAYS LOAD (NO CONDITION)
    _controller.loadChats(forceRefresh: true);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final providerChats =
        ref.watch(recentChatsProvider);

    final displayChats =
        providerChats.isNotEmpty
            ? providerChats
            : chats;

    if (loading &&
        chats.isEmpty &&
        providerChats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (providerChats.isEmpty &&
        chats.isEmpty) {
      return const Center(
        child: Text("No chats yet"),
      );
    }

    return ListView.builder(
      itemCount: displayChats.length,
      itemBuilder: (context, index) {
        final chat = displayChats[index];

        return ChatCard(
          chat: chat,
          onTap: () {
            final userId = chat["user"]["id"];

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

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/socket/socket_service.dart';

class ChatConversationScreen extends StatefulWidget {
  final String chatUserId;

  const ChatConversationScreen({
    super.key,
    required this.chatUserId,
  });

  @override
  State<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends State<ChatConversationScreen> {

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();

  List<dynamic> messages = [];
  String newMessage = "";
  bool loading = true;
  bool receiverOnline = false;
  bool isTyping = false;
  String? myId;
  dynamic selectedMsg;

  Timer? typingTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.go("/login");
      return;
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(
            base64Url.normalize(token.split(".")[1]))),
      );

      myId = payload["id"];

      await _fetchMessages();
      _connectSocket();

    } catch (_) {
      if (mounted) context.go("/login");
    }
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await ApiClient.get(
          "/chat/messages/${widget.chatUserId}");

      if (response["success"] == true) {
        setState(() {
          messages = response["data"];
        });

        await ApiClient.post("/chat/mark-read", {
          "senderId": widget.chatUserId
        });
      }
    } catch (_) {}

    if (mounted) {
      setState(() => loading = false);
      _scrollBottom();
    }
  }

  void _connectSocket() {
    if (myId == null) return;

    SocketService.connect(myId!);

    SocketService.onMessage((data) {
      if (!mounted) return;

      if (data["type"] == "NEW_MESSAGE") {
        final msg = data["data"];

        if ((msg["senderId"] == myId &&
                msg["receiverId"] == widget.chatUserId) ||
            (msg["senderId"] == widget.chatUserId &&
                msg["receiverId"] == myId)) {

          if (!messages.any((m) => m["id"] == msg["id"])) {
            setState(() {
              messages.add(msg);
            });
            _scrollBottom();
          }
        }
      }

      if (data["type"] == "MESSAGES_READ") {
        setState(() {
          messages = messages.map((m) {
            if (m["senderId"] == myId) {
              return {...m, "isRead": true};
            }
            return m;
          }).toList();
        });
      }
    });
  }

  Future<void> sendMessage() async {
    if (newMessage.trim().isEmpty) return;

    final messageText = newMessage;

    final tempMessage = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "senderId": myId,
      "receiverId": widget.chatUserId,
      "content": messageText,
      "isRead": false,
    };

    setState(() {
      messages.add(tempMessage);
      newMessage = "";
      _controller.clear();
    });

    _scrollBottom();

    try {
      await ApiClient.post("/chat/send", {
        "receiverId": widget.chatUserId,
        "content": messageText
      });
    } catch (_) {}
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    typingTimer?.cancel();
    SocketService.disconnect();
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),

      // ================= HEADER =================
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: AssetImage("assets/avatar.png"), // optional
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("User",
                    style: TextStyle(fontSize: 16)),
                if (isTyping)
                  const Text("Typing...",
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green)),
              ],
            )
          ],
        ),
        actions: const [
          Icon(Icons.call),
          SizedBox(width: 16),
          Icon(Icons.videocam),
          SizedBox(width: 16),
          Icon(Icons.more_vert),
          SizedBox(width: 10),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [

          // MESSAGE LIST
          Expanded(
            child: Container(
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
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {

                  final msg = messages[index];
                  final isMe = msg["senderId"] == myId;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        gradient: isMe
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF00F5A0),
                                  Color(0xFF00C9A7),
                                ],
                              )
                            : null,
                        color: isMe ? null : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        msg["content"].toString(),
                        style: TextStyle(
                          color: isMe ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ================= INPUT BAR =================
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF111111),
            ),
            child: Row(
              children: [

                const Icon(Icons.emoji_emotions_outlined,
                    color: Colors.white70),

                const SizedBox(width: 8),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [

                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            onChanged: (v) => newMessage = v,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        const Icon(Icons.camera_alt,
                            color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00F5A0),
                          Color(0xFF00C9A7),
                        ],
                      ),
                    ),
                    child: const Icon(Icons.send,
                        color: Colors.black, size: 20),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

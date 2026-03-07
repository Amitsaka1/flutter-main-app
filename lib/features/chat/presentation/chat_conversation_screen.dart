import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/controllers/conversation_controller.dart';
import 'package:app_project/features/call/presentation/call_screen.dart';
import '../../../core/controllers/chat_controller.dart';
import 'package:app_project/core/chat/unread_counter_service.dart';

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

  final ScrollController _scrollController =
      ScrollController();
  final TextEditingController _textController =
      TextEditingController();

  final ConversationController _logic =
      ConversationController.instance;

  StreamSubscription? _subscription;

  List<dynamic> messages = [];
  bool loading = true;
  String? myId;

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

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(
          base64Url.normalize(token.split(".")[1]))),
    );

    myId = payload["id"];

    _logic.init(myId!);

    _subscription = _logic
        .stream(widget.chatUserId)
        .listen((data) {
      if (!mounted) return;

      setState(() {
        messages = data;
        loading = false;
      });

      _scrollBottom();
    });

    await _logic.loadMessages(widget.chatUserId);
    ChatController.instance.markAsRead(widget.chatUserId);
    UnreadCounterService.clearChat(widget.chatUserId);
    
    ChatController.instance.markAsRead(widget.chatUserId);
  }

  Future<void> sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final text = _textController.text.trim();

    _textController.clear();

    await _logic.sendMessage(widget.chatUserId, text);
  }

  void _scrollBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ===========================
  // 🔥 START CALL FUNCTION
  // ===========================
  Future<void> _startCall(String type) async {

  if (myId == null) return;

  final response = await ApiClient.post("/call/start", {
    "callerId": myId,
    "receiverId": widget.chatUserId,
    "type": type
  });

  // 🔥 OFFLINE OR ERROR HANDLING
  if (response["success"] != true) {

  if (response["status"] == "OFFLINE") {

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          channelName: "",
          callType: type,
          initialStatus: "OFFLINE",
        ),
      ),
    );

    return;
  }

  String msg = response["message"] ?? "Call failed";

  if (msg == "Insufficient balance") {
    msg = "Low balance. Please recharge to make calls.";
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ),
  );

  return;
  }

  final sessionId = response["sessionId"];

  if (!mounted) return;

  // 🔥 RINGING STATE
  Navigator.push(
    context,
    MaterialPageRoute(
       builder: (_) => CallScreen(
        channelName: sessionId,
        callType: type,
        initialStatus: "RINGING", // 🔥 new param
       ),
    ),
  );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (loading && messages.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text("Chat"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startCall("VOICE_CALL"),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => _startCall("VIDEO_CALL"),
          ),
        ],
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe =
                    msg["senderId"] == myId;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12),
                    padding:
                        const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: isMe
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF00F5A0),
                                Color(0xFF00C9A7),
                              ],
                            )
                          : null,
                      color: isMe
                          ? null
                          : const Color(0xFF1E1E1E),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg["content"].toString(),
                      style: TextStyle(
                        color: isMe
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(
                        color: Colors.white),
                    decoration:
                        const InputDecoration(
                      hintText:
                          "Type a message...",
                      hintStyle: TextStyle(
                          color:
                              Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: sendMessage,
                  child: const Icon(
                    Icons.send,
                    color: Colors.green,
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

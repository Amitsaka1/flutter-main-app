import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/controllers/conversation_controller.dart';

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
  final TextEditingController _controller =
      TextEditingController();

  final ConversationController _controllerLogic =
      ConversationController.instance;

  StreamSubscription? _subscription;

  List<dynamic> messages = [];
  bool loading = true; // 🔥 start true
  String? myId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final token = await ApiClient.getToken();

    if (token == null) {
      if (mounted) context.pushReplacement("/login"); // 🔥 fixed
      return;
    }

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(
          base64Url.normalize(token.split(".")[1]))),
    );

    myId = payload["id"];

    _controllerLogic.init(myId!);

    _subscription = _controllerLogic
        .stream(widget.chatUserId)
        .listen((data) {
      if (!mounted) return;

      setState(() {
        messages = data;
        loading = false;
      });

      _scrollBottom();
    });

    await _controllerLogic
        .loadMessages(widget.chatUserId);
  }

  Future<void> sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();

    _controller.clear();

    await _controllerLogic
        .sendMessage(widget.chatUserId, text);
  }

  void _scrollBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    _controller.dispose();
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
            padding:
                const EdgeInsets.all(12),
            color: const Color(0xFF111111),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
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

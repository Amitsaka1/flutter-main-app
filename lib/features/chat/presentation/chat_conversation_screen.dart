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

  final ScrollController _scrollController =
      ScrollController();

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
    }
  }

  void _connectSocket() {

    if (myId == null) return;

    SocketService.connect(myId!);

    SocketService.onMessage((data) {

      if (!mounted) return;

      if (data["type"] == "NEW_MESSAGE") {

        final msg = data["data"];

        if (data["receiverOnline"] != null) {
          receiverOnline = data["receiverOnline"];
        }

        if ((msg["senderId"] == myId &&
                msg["receiverId"] ==
                    widget.chatUserId) ||
            (msg["senderId"] ==
                    widget.chatUserId &&
                msg["receiverId"] == myId)) {

          if (!messages
              .any((m) => m["id"] == msg["id"])) {
            setState(() {
              messages.add(msg);
            });
            _scrollBottom();
          }
        }
      }

      if (data["type"] == "MESSAGE_DELETED") {
        setState(() {
          messages = messages.map((m) {
            if (m["id"] ==
                data["messageId"]) {
              return {...m, "deleted": true};
            }
            return m;
          }).toList();
        });
      }

      if (data["type"] == "TYPING" &&
          data["from"] ==
              widget.chatUserId) {

        setState(() => isTyping = true);

        typingTimer?.cancel();
        typingTimer =
            Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => isTyping = false);
          }
        });
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

  // 🔥 Optimistic UI update
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
  });

  _scrollBottom();

  try {
    await ApiClient.post("/chat/send", {
      "receiverId": widget.chatUserId,
      "content": messageText
    });
  } catch (e) {
    debugPrint("Send error: $e");
  }
  }

  Future<void> deleteMessage(String mode) async {

    if (selectedMsg == null) return;

    final endpoint =
        mode == "me"
            ? "/chat/delete-for-me"
            : "/chat/delete-for-everyone";

    await ApiClient.post(endpoint, {
      "messageId": selectedMsg["id"]
    });

    if (mode == "me") {
      setState(() {
        messages.removeWhere(
            (m) => m["id"] ==
                selectedMsg["id"]);
      });
    }

    setState(() => selectedMsg = null);
  }

  void _scrollBottom() {
    Future.delayed(
        const Duration(milliseconds: 100),
        () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 300),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {
      return const Scaffold(
        body: Center(
            child: Text("Loading...")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Chat"),
            if (isTyping)
              const Text(
                " • Typing...",
                style: TextStyle(
                    color: Colors.green),
              )
          ],
        ),
      ),
      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              controller:
                  _scrollController,
              itemCount: messages.length,
              itemBuilder:
                  (context, index) {

                final msg = messages[index];
                final isMe =
                    msg["senderId"] ==
                        myId;

                return GestureDetector(
                  onLongPress: () {
                    setState(() =>
                        selectedMsg =
                            msg);
                  },
                  child: Align(
                    alignment: isMe
                        ? Alignment
                            .centerRight
                        : Alignment
                            .centerLeft,
                    child: Container(
                      margin:
                          const EdgeInsets
                              .all(8),
                      padding:
                          const EdgeInsets
                              .all(10),
                      decoration:
                          BoxDecoration(
                        color: isMe
                            ? Colors
                                .cyanAccent
                            : Colors
                                .grey[800],
                        borderRadius:
                            BorderRadius
                                .circular(
                                    18),
                      ),
                      child: msg[
                                  "deleted"] ==
                              true
                          ? const Text(
                              "This message was deleted",
                              style: TextStyle(
                                  fontStyle:
                                      FontStyle
                                          .italic),
                            )
                          : Text(
                              msg["content"]
                                  .toString(),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding:
                const EdgeInsets.all(
                    10),
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        newMessage = v,
                    decoration:
                        const InputDecoration(
                      hintText:
                          "Type a message...",
                    ),
                  ),
                ),

                IconButton(
                  icon:
                      const Icon(Icons.send),
                  onPressed:
                      sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

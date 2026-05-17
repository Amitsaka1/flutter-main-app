import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/controllers/chat_controller.dart';

import 'package:app_project/providers/recent_chats_provider.dart';

import 'widgets/chat_card.dart';
import 'widgets/chat_list_empty.dart';

class ChatListScreen
    extends ConsumerStatefulWidget {

  const ChatListScreen({
    super.key,
  });

  @override
  ConsumerState<ChatListScreen>
      createState() =>
          _ChatListScreenState();
}

class _ChatListScreenState
    extends ConsumerState<ChatListScreen>
    with AutomaticKeepAliveClientMixin {

  final ChatController _controller =
      ChatController.instance;

  List<dynamic> fallbackChats = [];

  bool loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {

    final token =
        await ApiClient.getToken();

    if (token == null) {

      if (mounted) {
        context.go("/login");
      }

      return;
    }

    // 🔥 CACHE
    if (_controller.hasData) {

      final cachedChats =
          List<dynamic>.from(
        _controller.chats,
      );

      WidgetsBinding.instance
          .addPostFrameCallback((_) {

        ref
            .read(
              recentChatsProvider
                  .notifier,
            )
            .state = cachedChats;
      });

      setState(() {
        fallbackChats = cachedChats;
        loading = false;
      });
    }

    // 🔥 API REFRESH
    try {

      final response =
          await ApiClient.get(
        "/chat/recent",
      );

      if (response["success"] == true) {

        final data =
            List<dynamic>.from(
          response["data"],
        );

        ref
            .read(
              recentChatsProvider
                  .notifier,
            )
            .state = data;

        if (mounted && loading) {
          setState(() {
            loading = false;
          });
        }
      }

    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final providerChats =
        ref.watch(
      recentChatsProvider,
    );

    final displayChats =
        providerChats.isNotEmpty
            ? providerChats
            : fallbackChats;

    // ================= UI START =================

    if (loading &&
        fallbackChats.isEmpty &&
        providerChats.isEmpty) {

      return const ChatListEmpty(
        loading: true,
      );
    }

    if (providerChats.isEmpty &&
        fallbackChats.isEmpty) {

      return const ChatListEmpty(
        loading: false,
      );
    }

    return ListView.builder(
      itemCount: displayChats.length,

      itemBuilder: (context, index) {

        final chat =
            displayChats[index];

        return ChatCard(
          chat: chat,

          onTap: () {

            final userId =
                chat["user"]["id"];

            context.push(
              "/chat/$userId",
            );
          },
        );
      },
    );

    // ================= UI END =================
  }
}

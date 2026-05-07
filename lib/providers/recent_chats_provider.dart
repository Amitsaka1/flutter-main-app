import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🔥 Recent Chats Provider
final recentChatsProvider =
    StateProvider<List<dynamic>>((ref) {
  return [];
});

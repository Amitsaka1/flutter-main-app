import 'dart:async';
import 'package:flutter/foundation.dart';
import '../database/cache_service.dart';

class GlobalDataManager {
  GlobalDataManager._internal();
  static final GlobalDataManager instance =
      GlobalDataManager._internal();

  List<dynamic>? profiles;
  List<dynamic>? chats;
  List<dynamic>? rooms;

  int unreadCount = 0;

  final StreamController<void> _controller =
      StreamController.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);

  // ─────────────────────────────────────────────
  // App open pe SQLite se load karo
  // ─────────────────────────────────────────────
  Future<void> loadFromCache() async {
    try {
      final cache = CacheService.instance;

      final p = await cache.getProfiles();
      final c = await cache.getChats();
      final r = await cache.getRooms();

      if (p.isNotEmpty) profiles = p;
      if (c.isNotEmpty) chats    = c;
      if (r.isNotEmpty) rooms    = r;

      debugPrint("✅ Cache loaded — "
          "profiles:${profiles?.length} "
          "chats:${chats?.length} "
          "rooms:${rooms?.length}");

      notify();
    } catch (e) {
      debugPrint("⚠️ loadFromCache failed: $e");
    }
  }

  // ─────────────────────────────────────────────
  // Profiles
  // ─────────────────────────────────────────────
  Future<void> setProfiles(List<dynamic> data) async {
    profiles = data;
    notify();
    await CacheService.instance.saveProfiles(data);
  }

  // ─────────────────────────────────────────────
  // Chats
  // ─────────────────────────────────────────────
  Future<void> setChats(List<dynamic> data) async {
    chats = data;
    notify();
    await CacheService.instance.saveChats(data);
  }

  // ─────────────────────────────────────────────
  // Rooms
  // ─────────────────────────────────────────────
  Future<void> setRooms(List<dynamic> data) async {
    rooms = data;
    notify();
    await CacheService.instance.saveRooms(data);
  }

  // ─────────────────────────────────────────────
  // Unread count
  // ─────────────────────────────────────────────
  void setUnread(int count) {
    unreadCount = count;
    notify();
  }

  // ─────────────────────────────────────────────
  // Logout pe sab clear
  // ─────────────────────────────────────────────
  Future<void> clear() async {
    profiles    = null;
    chats       = null;
    rooms       = null;
    unreadCount = 0;
    notify();
    await CacheService.instance.clearAll();
  }
}

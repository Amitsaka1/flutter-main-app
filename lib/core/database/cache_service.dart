import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'local_database.dart';

class CacheService {
  CacheService._internal();
  static final CacheService instance = CacheService._internal();

  // ─────────────────────────────────────────────
  // PROFILES
  // ─────────────────────────────────────────────

  Future<void> saveProfiles(List<dynamic> profiles) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      for (final p in profiles) {
        final id = p["userId"]?.toString() ?? p["id"]?.toString();
        if (id == null) continue;
        batch.insert("profiles", {
          "id":         id,
          "data":       jsonEncode(p),
          "updated_at": now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint("✅ Profiles cached: ${profiles.length}");
    } catch (e) {
      debugPrint("⚠️ saveProfiles failed: $e");
    }
  }

  Future<List<dynamic>> getProfiles() async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query("profiles", orderBy: "updated_at DESC");
      return rows.map((r) => jsonDecode(r["data"] as String)).toList();
    } catch (e) {
      debugPrint("⚠️ getProfiles failed: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // CHATS
  // ─────────────────────────────────────────────

  Future<void> saveChats(List<dynamic> chats) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      for (final c in chats) {
        final id = c["id"]?.toString() ?? c["_id"]?.toString();
        if (id == null) continue;
        batch.insert("chats", {
          "id":         id,
          "data":       jsonEncode(c),
          "updated_at": now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint("✅ Chats cached: ${chats.length}");
    } catch (e) {
      debugPrint("⚠️ saveChats failed: $e");
    }
  }

  Future<List<dynamic>> getChats() async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query("chats", orderBy: "updated_at DESC");
      return rows.map((r) => jsonDecode(r["data"] as String)).toList();
    } catch (e) {
      debugPrint("⚠️ getChats failed: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // MESSAGES
  // ─────────────────────────────────────────────

  Future<void> saveMessages(
      String conversationId, List<dynamic> messages) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      for (final m in messages) {
        final id = m["id"]?.toString() ?? m["_id"]?.toString();
        if (id == null) continue;
        batch.insert("messages", {
          "id":              id,
          "conversation_id": conversationId,
          "data":            jsonEncode(m),
          "updated_at":      now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint("✅ Messages cached: ${messages.length}");
    } catch (e) {
      debugPrint("⚠️ saveMessages failed: $e");
    }
  }

  Future<List<dynamic>> getMessages(String conversationId) async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query(
        "messages",
        where:    "conversation_id = ?",
        whereArgs: [conversationId],
        orderBy:  "updated_at ASC",
      );
      return rows.map((r) => jsonDecode(r["data"] as String)).toList();
    } catch (e) {
      debugPrint("⚠️ getMessages failed: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // ROOMS (Voice World)
  // ─────────────────────────────────────────────

  Future<void> saveRooms(List<dynamic> rooms) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      for (final r in rooms) {
        final id = r["id"]?.toString() ?? r["_id"]?.toString();
        if (id == null) continue;
        batch.insert("rooms", {
          "id":         id,
          "data":       jsonEncode(r),
          "updated_at": now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
      debugPrint("✅ Rooms cached: ${rooms.length}");
    } catch (e) {
      debugPrint("⚠️ saveRooms failed: $e");
    }
  }

  Future<List<dynamic>> getRooms() async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query("rooms", orderBy: "updated_at DESC");
      return rows.map((r) => jsonDecode(r["data"] as String)).toList();
    } catch (e) {
      debugPrint("⚠️ getRooms failed: $e");
      return [];
    }
  }

  // ─────────────────────────────────────────────
  // MY PROFILE
  // ─────────────────────────────────────────────

  Future<void> saveMyProfile(Map<String, dynamic> profile) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert("my_profile", {
        "id":         "me",
        "data":       jsonEncode(profile),
        "updated_at": now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint("✅ My profile cached");
    } catch (e) {
      debugPrint("⚠️ saveMyProfile failed: $e");
    }
  }

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query(
        "my_profile",
        where:     "id = ?",
        whereArgs: ["me"],
      );
      if (rows.isEmpty) return null;
      return jsonDecode(rows.first["data"] as String)
          as Map<String, dynamic>;
    } catch (e) {
      debugPrint("⚠️ getMyProfile failed: $e");
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // OFFLINE MESSAGE QUEUE
  // ─────────────────────────────────────────────

  Future<void> addToQueue(
      String tempId, String conversationId, Map<String, dynamic> data) async {
    try {
      final db  = await LocalDatabase.instance.db;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert("message_queue", {
        "id":              tempId,
        "conversation_id": conversationId,
        "data":            jsonEncode(data),
        "created_at":      now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      debugPrint("✅ Message added to queue: $tempId");
    } catch (e) {
      debugPrint("⚠️ addToQueue failed: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    try {
      final db   = await LocalDatabase.instance.db;
      final rows = await db.query(
        "message_queue",
        orderBy: "created_at ASC",
      );
      return rows.map((r) => {
        "id":              r["id"],
        "conversation_id": r["conversation_id"],
        "data":            jsonDecode(r["data"] as String),
      }).toList();
    } catch (e) {
      debugPrint("⚠️ getQueue failed: $e");
      return [];
    }
  }

  Future<void> removeFromQueue(String tempId) async {
    try {
      final db = await LocalDatabase.instance.db;
      await db.delete(
        "message_queue",
        where:     "id = ?",
        whereArgs: [tempId],
      );
      debugPrint("✅ Message removed from queue: $tempId");
    } catch (e) {
      debugPrint("⚠️ removeFromQueue failed: $e");
    }
  }

  // ─────────────────────────────────────────────
  // LOGOUT PE SAB CLEAR
  // ─────────────────────────────────────────────

  Future<void> clearAll() async {
    try {
      final db = await LocalDatabase.instance.db;
      await db.delete("profiles");
      await db.delete("chats");
      await db.delete("messages");
      await db.delete("rooms");
      await db.delete("my_profile");
      await db.delete("message_queue");
      debugPrint("✅ Cache cleared");
    } catch (e) {
      debugPrint("⚠️ clearAll failed: $e");
    }
  }
}

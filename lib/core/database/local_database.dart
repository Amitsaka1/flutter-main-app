import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  LocalDatabase._internal();
  static final LocalDatabase instance = LocalDatabase._internal();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'app_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {

    // ── Profiles table ──────────────────────────
    await db.execute('''
      CREATE TABLE profiles (
        id          TEXT PRIMARY KEY,
        data        TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── Chats table ─────────────────────────────
    await db.execute('''
      CREATE TABLE chats (
        id          TEXT PRIMARY KEY,
        data        TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── Messages table ───────────────────────────
    await db.execute('''
      CREATE TABLE messages (
        id             TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        data           TEXT NOT NULL,
        updated_at     INTEGER NOT NULL
      )
    ''');

    // ── Rooms table (Voice World) ────────────────
    await db.execute('''
      CREATE TABLE rooms (
        id          TEXT PRIMARY KEY,
        data        TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── My profile table ─────────────────────────
    await db.execute('''
      CREATE TABLE my_profile (
        id          TEXT PRIMARY KEY,
        data        TEXT NOT NULL,
        updated_at  INTEGER NOT NULL
      )
    ''');

    // ── Offline message queue ────────────────────
    await db.execute('''
      CREATE TABLE message_queue (
        id              TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        data            TEXT NOT NULL,
        created_at      INTEGER NOT NULL
      )
    ''');
  }

  // ── DB band karo ────────────────────────────
  Future<void> close() async {
    final d = _db;
    if (d != null) {
      await d.close();
      _db = null;
    }
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Base SQLite locale, embarquée sur chaque appareil, qui conserve les
/// appels (patients ET personnel) tant qu'ils n'ont pas été confirmés
/// envoyés au serveur Supabase. Permet à un poste de continuer à
/// fonctionner même en cas de coupure réseau temporaire.
///
/// Version 2 : ajout de la table `pending_staff_calls` pour le volet
/// "Appel du personnel soignant". Les installations existantes (version 1)
/// reçoivent automatiquement cette table via [onUpgrade].
class LocalDb {
  LocalDb._();
  static final LocalDb instance = LocalDb._();

  Database? _db;

  static const _createPendingCalls = '''
    CREATE TABLE IF NOT EXISTS pending_calls (
      id TEXT PRIMARY KEY,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static const _createPendingStaffCalls = '''
    CREATE TABLE IF NOT EXISTS pending_staff_calls (
      id TEXT PRIMARY KEY,
      payload TEXT NOT NULL,
      created_at TEXT NOT NULL,
      attempts INTEGER NOT NULL DEFAULT 0
    )
  ''';

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'medicall_pro_offline.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(_createPendingCalls);
        await db.execute(_createPendingStaffCalls);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(_createPendingStaffCalls);
        }
      },
    );
    return _db!;
  }

  // ---------- Appels de patients ----------

  Future<void> insertPending(String id, String jsonPayload) async {
    final db = await database;
    await db.insert(
      'pending_calls',
      {
        'id': id,
        'payload': jsonPayload,
        'created_at': DateTime.now().toIso8601String(),
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllPending() async {
    final db = await database;
    return db.query('pending_calls', orderBy: 'created_at ASC');
  }

  Future<int> countPending() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM pending_calls');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> incrementAttempts(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_calls SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> remove(String id) async {
    final db = await database;
    await db.delete('pending_calls', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Appels du personnel soignant ----------

  Future<void> insertPendingStaff(String id, String jsonPayload) async {
    final db = await database;
    await db.insert(
      'pending_staff_calls',
      {
        'id': id,
        'payload': jsonPayload,
        'created_at': DateTime.now().toIso8601String(),
        'attempts': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, Object?>>> getAllPendingStaff() async {
    final db = await database;
    return db.query('pending_staff_calls', orderBy: 'created_at ASC');
  }

  Future<int> countPendingStaff() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS c FROM pending_staff_calls');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> incrementStaffAttempts(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE pending_staff_calls SET attempts = attempts + 1 WHERE id = ?',
      [id],
    );
  }

  Future<void> removeStaff(String id) async {
    final db = await database;
    await db.delete('pending_staff_calls', where: 'id = ?', whereArgs: [id]);
  }
}

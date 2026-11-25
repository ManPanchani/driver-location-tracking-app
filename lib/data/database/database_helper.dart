import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/location_model.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  static const String _databaseName = 'driver_tracking.db';
  static const String _tableName = 'locations';

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            captured_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'pending',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_locations_status
          ON $_tableName(status)
        ''');

        await db.execute('''
          CREATE INDEX idx_locations_captured_at
          ON $_tableName(captured_at)
        ''');
      },
    );
  }

  // Save a location only once.
  Future<bool> insertLocation(LocationModel location) async {
    final db = await database;

    final result = await db.insert(
      _tableName,
      location.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return result != -1;
  }

  // Get all location records.
  Future<List<LocationModel>> getAllLocations() async {
    final db = await database;

    final result = await db.query(_tableName, orderBy: 'captured_at DESC');

    return result.map(LocationModel.fromMap).toList();
  }

  // Get records waiting for synchronization.
  Future<List<LocationModel>> getPendingLocations({int limit = 100}) async {
    final db = await database;

    final result = await db.query(
      _tableName,
      where: "status IN (?, ?)",
      whereArgs: ['pending', 'failed'],
      orderBy: 'captured_at ASC',
      limit: limit,
    );

    return result.map(LocationModel.fromMap).toList();
  }

  // Mark a record as successfully synchronized.
  Future<void> markSynced(String id) async {
    final db = await database;

    await db.update(
      _tableName,
      {'status': 'synced', 'last_error': null},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Save failure information and increment retry count.
  Future<void> markFailed(String id, String error) async {
    final db = await database;

    await db.rawUpdate(
      '''
      UPDATE $_tableName
      SET status = ?,
          retry_count = retry_count + 1,
          last_error = ?
      WHERE id = ?
      ''',
      ['failed', error, id],
    );
  }

  // Return dashboard statistics.
  Future<Map<String, int>> getStatistics() async {
    final db = await database;

    final result = await db.rawQuery('''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN status = 'synced' THEN 1 ELSE 0 END) AS synced,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending,
        SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) AS failed
      FROM $_tableName
    ''');

    final row = result.first;

    return {
      'total': (row['total'] as int?) ?? 0,
      'synced': (row['synced'] as int?) ?? 0,
      'pending': (row['pending'] as int?) ?? 0,
      'failed': (row['failed'] as int?) ?? 0,
    };
  }

  // Get one record by its unique ID.
  Future<LocationModel?> getLocationById(String id) async {
    final db = await database;

    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return LocationModel.fromMap(result.first);
  }

  // Close database when required.
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

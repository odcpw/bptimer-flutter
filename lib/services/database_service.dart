/// DatabaseService - SQLite database operations for meditation timer
/// 
/// Handles all database operations including session storage, SMA management,
/// and data migration. Uses result-based error handling instead of exceptions
/// to match PWA code style preferences.

library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/session.dart';
import '../models/sma.dart';
import '../utils/result.dart';

class DatabaseService {
  static Database? _database;
  static const String _dbName = 'meditation_timer.db';
  static const int _dbVersion = 1;

  /// Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Get database instance, creating if necessary
  Future<DatabaseResult<Database>> get database async {
    if (_database != null) return Success(_database!);
    
    final result = await _initDatabase();
    if (result.isSuccess) {
      _database = result.data!;
      return Success(_database!);
    }
    return Failure(DatabaseError.connectionFailed);
  }

  /// Initialize SQLite database with required tables
  Future<DatabaseResult<Database>> _initDatabase() async {
    String path = join(await getDatabasesPath(), _dbName);
    
    final db = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeDatabase,
    );
    return Success(db);
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Sessions table - stores completed meditation sessions
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        duration INTEGER NOT NULL,
        practices TEXT,
        notes TEXT,
        posture TEXT,
        completed_at TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // SMAs table - stores Special Mindfulness Activities
    await db.execute('''
      CREATE TABLE smas (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        frequency TEXT NOT NULL,
        times_per_day INTEGER DEFAULT 1,
        reminder_windows TEXT DEFAULT 'morning,midday,afternoon,evening',
        notifications_enabled INTEGER DEFAULT 1,
        day_of_week INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        last_reminder_at TEXT,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Settings table - stores app preferences
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_sessions_date ON sessions(date)');
    await db.execute('CREATE INDEX idx_smas_frequency ON smas(frequency)');
    await db.execute('CREATE INDEX idx_smas_enabled ON smas(notifications_enabled)');
  }

  /// Handle database upgrades
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle future schema migrations here
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE sessions ADD COLUMN new_column TEXT');
    }
  }

  /// Close database connection
  Future<VoidResult> close() async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    await dbResult.data!.close();
    _database = null;
    return const Success(null);
  }

  // ===== SESSION OPERATIONS =====

  /// Save a meditation session
  Future<DatabaseResult<int>> saveSession(Session session) async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final rowId = await dbResult.data!.insert(
        'sessions',
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[DB] Session saved: id=${session.id}, duration=${session.duration}s, practices=${session.practices.length}');
      return Success(rowId);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to save session: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Get all sessions ordered by date (newest first)
  Future<DatabaseResult<List<Session>>> getAllSessions() async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final List<Map<String, dynamic>> maps = await dbResult.data!.query(
        'sessions',
        orderBy: 'date DESC',
      );
      final sessions = maps.map((map) => Session.fromMap(map)).toList();
      debugPrint('[DB] Sessions loaded: count=${sessions.length}');
      return Success(sessions);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to load sessions: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Get sessions for a specific date range
  Future<DatabaseResult<List<Session>>> getSessionsForPeriod(DateTime start, DateTime end) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final List<Map<String, dynamic>> maps = await dbResult.data!.query(
      'sessions',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date DESC',
    );
    final sessions = maps.map((map) => Session.fromMap(map)).toList();
    return Success(sessions);
  }

  /// Get sessions from the last N days
  Future<DatabaseResult<List<Session>>> getRecentSessions(int days) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    return await getSessionsForPeriod(start, end);
  }

  /// Get session by ID
  Future<DatabaseResult<Session?>> getSessionById(String id) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final List<Map<String, dynamic>> maps = await dbResult.data!.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return const Success(null);
    final session = Session.fromMap(maps.first);
    return Success(session);
  }

  /// Delete session by ID
  Future<DatabaseResult<int>> deleteSession(String id) async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final rowsDeleted = await dbResult.data!.delete(
        'sessions',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[DB] Session deleted: $id');
      return Success(rowsDeleted);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to delete session: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Update session
  Future<DatabaseResult<int>> updateSession(Session session) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final rowsUpdated = await dbResult.data!.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
    return Success(rowsUpdated);
  }

  /// Get total meditation time (in seconds) for a date range
  Future<DatabaseResult<int>> getTotalMeditationTime(DateTime start, DateTime end) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final result = await dbResult.data!.rawQuery(
      'SELECT SUM(duration) as total FROM sessions WHERE date BETWEEN ? AND ?',
      [start.toIso8601String(), end.toIso8601String()],
    );
    
    final total = (result.first['total'] as int?) ?? 0;
    return Success(total);
  }

  // ===== SMA OPERATIONS =====

  /// Save an SMA
  Future<DatabaseResult<int>> saveSMA(SMA sma) async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final rowId = await dbResult.data!.insert(
        'smas',
        sma.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      debugPrint('[DB] SMA saved: ${sma.name}, frequency=${sma.frequency}, notifications=${sma.notificationsEnabled}');
      return Success(rowId);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to save SMA: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Get all SMAs
  Future<DatabaseResult<List<SMA>>> getAllSMAs() async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final List<Map<String, dynamic>> maps = await dbResult.data!.query(
        'smas',
        orderBy: 'created_at ASC',
      );
      final smas = maps.map((map) => SMA.fromMap(map)).toList();
      debugPrint('[DB] SMAs loaded: count=${smas.length}');
      return Success(smas);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to load SMAs: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Get enabled SMAs only
  Future<DatabaseResult<List<SMA>>> getEnabledSMAs() async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final List<Map<String, dynamic>> maps = await dbResult.data!.query(
      'smas',
      where: 'notifications_enabled = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );
    final smas = maps.map((map) => SMA.fromMap(map)).toList();
    return Success(smas);
  }

  /// Get SMA by ID
  Future<DatabaseResult<SMA?>> getSMAById(String id) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final List<Map<String, dynamic>> maps = await dbResult.data!.query(
      'smas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return const Success(null);
    final sma = SMA.fromMap(maps.first);
    return Success(sma);
  }

  /// Update SMA
  Future<DatabaseResult<int>> updateSMA(SMA sma) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final rowsUpdated = await dbResult.data!.update(
      'smas',
      sma.toMap(),
      where: 'id = ?',
      whereArgs: [sma.id],
    );
    return Success(rowsUpdated);
  }

  /// Delete SMA by ID
  Future<DatabaseResult<int>> deleteSMA(String id) async {
    try {
      final dbResult = await database;
      if (dbResult.isFailure) return Failure(dbResult.error!);
      
      final rowsDeleted = await dbResult.data!.delete(
        'smas',
        where: 'id = ?',
        whereArgs: [id],
      );
      debugPrint('[DB] SMA deleted: $id');
      return Success(rowsDeleted);
    } catch (e) {
      debugPrint('[ERROR][DB] Failed to delete SMA: $e');
      return Failure(DatabaseError.storageError);
    }
  }

  /// Mark SMA as reminded (update last_reminder_at)
  Future<DatabaseResult<int>> markSMAAsReminded(String id) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final rowsUpdated = await dbResult.data!.update(
      'smas',
      {
        'last_reminder_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return Success(rowsUpdated);
  }

  // ===== SETTINGS OPERATIONS =====

  /// Save a setting
  Future<DatabaseResult<int>> saveSetting(String key, String value) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final rowId = await dbResult.data!.insert(
      'settings',
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return Success(rowId);
  }

  /// Get a setting value
  Future<DatabaseResult<String?>> getSetting(String key) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final List<Map<String, dynamic>> maps = await dbResult.data!.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    
    if (maps.isEmpty) return const Success(null);
    final value = maps.first['value'] as String?;
    return Success(value);
  }

  /// Delete a setting
  Future<DatabaseResult<int>> deleteSetting(String key) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final rowsDeleted = await dbResult.data!.delete(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return Success(rowsDeleted);
  }

  // ===== UTILITY OPERATIONS =====

  /// Clear all data (for testing or reset)
  Future<VoidResult> clearAllData() async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    await dbResult.data!.transaction((txn) async {
      await txn.delete('sessions');
      await txn.delete('smas');
      await txn.delete('settings');
    });
    return const Success(null);
  }

  /// Get database statistics
  Future<DatabaseResult<Map<String, int>>> getDatabaseStats() async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    final sessionCount = Sqflite.firstIntValue(
      await dbResult.data!.rawQuery('SELECT COUNT(*) FROM sessions')
    ) ?? 0;
    
    final smaCount = Sqflite.firstIntValue(
      await dbResult.data!.rawQuery('SELECT COUNT(*) FROM smas')
    ) ?? 0;
    
    final totalMeditationTime = Sqflite.firstIntValue(
      await dbResult.data!.rawQuery('SELECT SUM(duration) FROM sessions')
    ) ?? 0;
    
    final stats = {
      'sessions': sessionCount,
      'smas': smaCount,
      'totalMeditationTime': totalMeditationTime,
    };
    return Success(stats);
  }

  /// Export all data as JSON
  Future<DatabaseResult<Map<String, dynamic>>> exportData() async {
    final sessionsResult = await getAllSessions();
    if (sessionsResult.isFailure) return Failure(sessionsResult.error!);
    
    final smasResult = await getAllSMAs();
    if (smasResult.isFailure) return Failure(smasResult.error!);
    
    final exportData = {
      'version': _dbVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'sessions': sessionsResult.data!.map((s) => s.toJson()).toList(),
      'smas': smasResult.data!.map((s) => s.toJson()).toList(),
    };
    return Success(exportData);
  }

  /// Import data from JSON (for PWA migration)
  Future<VoidResult> importData(Map<String, dynamic> data) async {
    final dbResult = await database;
    if (dbResult.isFailure) return Failure(dbResult.error!);
    
    await dbResult.data!.transaction((txn) async {
      // Import sessions
      if (data['sessions'] != null) {
        for (final sessionData in data['sessions']) {
          final session = Session.fromJson(sessionData);
          await txn.insert('sessions', session.toMap(), 
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
      
      // Import SMAs
      if (data['smas'] != null) {
        for (final smaData in data['smas']) {
          final sma = SMA.fromJson(smaData);
          await txn.insert('smas', sma.toMap(), 
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
    return const Success(null);
  }
}
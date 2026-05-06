import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as mobile;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqlcipher_library_windows/sqlcipher_library_windows.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

import '../constants/db_queries.dart';
import 'encryption_service.dart';

/// Centralized database service for initializing and accessing the SQLite database.
///
/// Supports both mobile (sqflite) and desktop (sqflite_common_ffi).
/// The database is encrypted using a passphrase stored in secure storage.
class DatabaseService {
  static Database? _database;
  static const int _dbVersion = 1;
  static const String _dbName = 'student_management.db';

  // ignore: unused_field
  final EncryptionService _encryptionService;

  DatabaseService({required EncryptionService encryptionService})
    : _encryptionService = encryptionService;

  /// Returns the singleton database instance, initializing if needed.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database factory for the current platform.
  static void initPlatform() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      if (Platform.isWindows) {
        sqlite_open.open.overrideFor(
          sqlite_open.OperatingSystem.windows,
          openSQLCipherOnWindows,
        );
      }
      ffi.sqfliteFfiInit();
      // We don't override the global databaseFactory to avoid typing issues with sqflite_sqlcipher
    }
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await _getDatabasePath();
    final String password = await _encryptionService.getDatabaseKey();

    if (kDebugMode) {
      print('Database path: $dbPath');
    }

    try {
      return await _openDbWithPassword(dbPath, password);
    } catch (e) {
      // If the database is an old unencrypted database, SQLCipher will throw "file is not a database".
      // We will backup the old DB and create a fresh encrypted one.
      if (e.toString().contains('not a database')) {
        if (kDebugMode) {
          print(
            'Found old unencrypted DB, renaming to .old and starting fresh encrypted one.',
          );
        }
        try {
          final File oldDb = File(dbPath);
          if (await oldDb.exists()) {
            await oldDb.rename('$dbPath.old');
          }
        } catch (_) {}
        // Try opening again
        return await _openDbWithPassword(dbPath, password);
      }
      rethrow;
    }
  }

  Future<Database> _openDbWithPassword(String dbPath, String password) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return ffi.databaseFactoryFfi.openDatabase(
        dbPath,
        options: ffi.OpenDatabaseOptions(
          version: _dbVersion,
          onCreate: _onCreate,
          onOpen: _onOpen,
          onConfigure: (db) async {
            // Execute PRAGMA key first to unlock the SQLCipher database
            await db.execute("PRAGMA key = '$password'");
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
    } else {
      return mobile.openDatabase(
        dbPath,
        password: password,
        version: _dbVersion,
        onCreate: _onCreate,
        onOpen: _onOpen,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    }
  }

  Future<String> _getDatabasePath() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory dbDir = Directory(
      join(documentsDir.path, 'StudentManagement'),
    );
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }
    return join(dbDir.path, _dbName);
  }

  /// Create all tables on first launch.
  Future<void> _onCreate(Database db, int version) async {
    final Batch batch = db.batch();

    batch.execute(DBQueries.createUsersTable);
    batch.execute(DBQueries.createGroupsTable);
    batch.execute(DBQueries.createGroupSchedulesTable);
    batch.execute(DBQueries.createStudentsTable);
    batch.execute(DBQueries.createPaymentsTable);
    batch.execute(DBQueries.createAttendanceTable);
    batch.execute(DBQueries.createAssistantsTable);
    batch.execute(DBQueries.createAssistantAttendanceTable);
    batch.execute(DBQueries.createExamsTable);
    batch.execute(DBQueries.createExamGroupsTable);
    batch.execute(DBQueries.createMarksTable);
    batch.execute(DBQueries.createNotesTable);
    batch.execute(DBQueries.createStudentNotesTable);
    batch.execute(DBQueries.createAppSettingsTable);
    batch.execute(DBQueries.createDeviceBindingTable);
    batch.execute(DBQueries.createLoginAttemptsTable);

    await batch.commit(noResult: true);

    // Create indexes for performance
    await db.execute(DBQueries.createIdxStudentsGroup);
    await db.execute(DBQueries.createIdxPaymentsStudent);
    await db.execute(DBQueries.createIdxAttendanceStudent);
    await db.execute(DBQueries.createIdxAttendanceDate);
    await db.execute(DBQueries.createIdxMarksExam);
    await db.execute(DBQueries.createIdxMarksStudent);
    await db.execute(DBQueries.createIdxGroupSchedulesGroup);
    await db.execute(DBQueries.createIdxAssistantAttendanceAssistant);
    await db.execute(DBQueries.createIdxAssistantAttendanceDate);
    await db.execute(DBQueries.createIdxLoginAttemptsUsername);
  }

  /// Ensure all required tables exist on every open.
  /// This handles existing databases that were created at an older version.
  Future<void> _onOpen(Database db) async {
    if (kDebugMode) {
      print('Running _onOpen: ensuring all required tables exist...');
    }

    // Tables
    await db.execute(DBQueries.createUsersTable);
    await db.execute(DBQueries.createGroupsTable);
    await db.execute(DBQueries.createGroupSchedulesTable);
    await db.execute(DBQueries.createStudentsTable);
    await db.execute(DBQueries.createPaymentsTable);
    await db.execute(DBQueries.createAttendanceTable);
    await db.execute(DBQueries.createAssistantsTable);
    await db.execute(DBQueries.createAssistantAttendanceTable);
    await db.execute(DBQueries.createExamsTable);
    await db.execute(DBQueries.createExamGroupsTable);
    await db.execute(DBQueries.createMarksTable);
    await db.execute(DBQueries.createNotesTable);
    await db.execute(DBQueries.createStudentNotesTable);
    await db.execute(DBQueries.createAppSettingsTable);
    await db.execute(DBQueries.createDeviceBindingTable);
    await db.execute(DBQueries.createLoginAttemptsTable);

    // Ensure columns added in past migrations exist
    try {
      await db.execute(DBQueries.alterUsersAddSalt);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterUsersAddMustChangePassword);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterStudentsAddGrade);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterStudentsAddStatus);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterStudentsAddAttendanceDay);
    } catch (_) {}

    // Ensure indexes exist
    try {
      await db.execute(DBQueries.createIdxStudentsGroup);
      await db.execute(DBQueries.createIdxPaymentsStudent);
      await db.execute(DBQueries.createIdxAttendanceStudent);
      await db.execute(DBQueries.createIdxAttendanceDate);
      await db.execute(DBQueries.createIdxMarksExam);
      await db.execute(DBQueries.createIdxMarksStudent);
      await db.execute(DBQueries.createIdxGroupSchedulesGroup);
      await db.execute(DBQueries.createIdxAssistantAttendanceAssistant);
      await db.execute(DBQueries.createIdxAssistantAttendanceDate);
      await db.execute(DBQueries.createIdxLoginAttemptsUsername);
    } catch (_) {}
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

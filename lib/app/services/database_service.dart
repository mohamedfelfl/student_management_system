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
  final Future<String> Function()? _databasePath;

  DatabaseService({
    required EncryptionService encryptionService,
    Future<String> Function()? databasePath,
  }) : _encryptionService = encryptionService,
       _databasePath = databasePath;

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
      // SQLCipher reports a wrong key exactly like a corrupt file. Never move
      // or replace the file here: the user decides on the recovery screen.
      if (e.toString().contains('not a database')) {
        throw DatabaseUnlockException(dbPath, e);
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
            await db.execute('PRAGMA busy_timeout = 5000');
            await db.execute('PRAGMA journal_mode = WAL');
            await db.execute('PRAGMA synchronous = NORMAL');
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
          await db.execute('PRAGMA busy_timeout = 5000');
          await db.execute('PRAGMA journal_mode = WAL');
          await db.execute('PRAGMA synchronous = NORMAL');
        },
      );
    }
  }

  Future<String> _getDatabasePath() async {
    if (_databasePath != null) return _databasePath();
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
    batch.execute(DBQueries.createLessonsTable);
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
    await db.execute(DBQueries.createIdxLessonsGroup);
    await db.execute(DBQueries.createIdxLessonsDate);
    await db.execute(DBQueries.createIdxLessonsStatus);
    await db.execute(DBQueries.createIdxAttendanceLesson);
    await db.execute(DBQueries.createIdxStudentsSerial);
    await db.execute(DBQueries.createIdxStudentsName);
    await db.execute(DBQueries.createIdxAttendanceLessonStudent);
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
    await db.execute(DBQueries.createLessonsTable);
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
      await db.execute(DBQueries.alterGroupsAddGrade);
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
    try {
      await db.execute(DBQueries.alterStudentsAddNotes);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterAttendanceAddLessonId);
    } catch (_) {}
    try {
      await db.execute(DBQueries.alterLessonsAddCreatedAt);
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
      await db.execute(DBQueries.createIdxLessonsGroup);
      await db.execute(DBQueries.createIdxLessonsDate);
      await db.execute(DBQueries.createIdxLessonsStatus);
      await db.execute(DBQueries.createIdxAttendanceLesson);
      await db.execute(DBQueries.createIdxStudentsSerial);
      await db.execute(DBQueries.createIdxStudentsName);
      await db.execute(DBQueries.createIdxAttendanceLessonStudent);
    } catch (_) {}

    // Auto-migrate legacy attendance records without a lesson_id
    try {
      final List<Map<String, Object?>> unlinked = await db.rawQuery('''
        SELECT DISTINCT a.date, s.group_id
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        WHERE a.lesson_id IS NULL AND s.group_id IS NOT NULL
      ''');

      for (final row in unlinked) {
        final String date = row['date'] as String;
        final int groupId = row['group_id'] as int;

        final List<Map<String, Object?>> existingLesson = await db.query(
          DBQueries.tableLessons,
          where: 'group_id = ? AND date = ?',
          whereArgs: [groupId, date],
          limit: 1,
        );

        int lessonId;
        if (existingLesson.isNotEmpty) {
          lessonId = existingLesson.first['id'] as int;
        } else {
          lessonId = await db.insert(DBQueries.tableLessons, {
            'group_id': groupId,
            'date': date,
            'start_time': '00:00',
            'status': 'completed',
            'title': 'Legacy Session',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        await db.rawUpdate('''
          UPDATE attendance
          SET lesson_id = ?
          WHERE date = ? AND lesson_id IS NULL AND student_id IN (
            SELECT id FROM students WHERE group_id = ?
          )
        ''', [lessonId, date, groupId]);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Legacy attendance migration notice: $e');
      }
    }

    // Clean group names to remove redundant stage numbers (e.g. "1 ث", "2 ث", "3 ث")
    try {
      final List<Map<String, Object?>> groupRows =
          await db.query(DBQueries.tableGroups);
      for (final g in groupRows) {
        final id = g['id'] as int;
        final rawName = g['name']?.toString() ?? '';
        String cleanName = rawName.replaceAll('الثللاثاء', 'الثلاثاء');
        cleanName = cleanName.replaceAll(RegExp(r'\s*[123]\s*ث\s*'), ' ');
        cleanName = cleanName.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleanName != rawName && cleanName.isNotEmpty) {
          await db.update(
            DBQueries.tableGroups,
            {'name': cleanName},
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }
    } catch (_) {}

    // Never delete students here. Two students may legitimately share a name
    // (siblings, common names), and deleting one cascades to their payments,
    // attendance, marks and notes. Duplicates are resolved only through the
    // user-confirmed merge flow (StudentMergeService).
  }

  /// Runs the on-open routine against [db] so tests can simulate an app restart.
  @visibleForTesting
  Future<void> runOnOpenForTesting(Database db) => _onOpen(db);

  /// Moves an unreadable database file (and its WAL/SHM side files) aside
  /// under a unique timestamped name, so the next access creates an empty
  /// database. Nothing is deleted. Returns the new path of the moved file.
  Future<String> quarantineDatabaseAndStartFresh() async {
    await close();
    final String dbPath = await _getDatabasePath();
    final String stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    String target = '$dbPath.unreadable-$stamp';
    for (int n = 1; await File(target).exists(); n++) {
      target = '$dbPath.unreadable-$stamp-$n';
    }

    await File(dbPath).rename(target);
    for (final String suffix in ['-wal', '-shm']) {
      final File side = File('$dbPath$suffix');
      if (await side.exists()) {
        await side.rename('$target$suffix');
      }
    }
    return target;
  }

  /// Throws [DatabaseUnlockException] unless [path] is a database this device
  /// can unlock. Used before restoring a backup over the live database.
  Future<void> verifyCanOpen(String path) async {
    final String password = await _encryptionService.getDatabaseKey();
    Database? db;
    try {
      db = await _openWithKeyOnly(path, password);
      final List<Map<String, Object?>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        [DBQueries.tableStudents],
      );
      if (tables.isEmpty) {
        throw StateError('Not a Student Management database');
      }
    } catch (e) {
      throw DatabaseUnlockException(path, e);
    } finally {
      await db?.close();
    }
  }

  /// Opens [path] with the encryption key but without creating tables or
  /// running the on-open maintenance.
  Future<Database> _openWithKeyOnly(String path, String password) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return ffi.databaseFactoryFfi.openDatabase(
        path,
        options: ffi.OpenDatabaseOptions(
          onConfigure: (db) => db.execute("PRAGMA key = '$password'"),
        ),
      );
    }
    return mobile.openDatabase(path, password: password);
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Thrown when the database file exists but cannot be opened with this
/// device's encryption key (lost key, or a database copied from elsewhere).
class DatabaseUnlockException implements Exception {
  final String path;
  final Object cause;

  const DatabaseUnlockException(this.path, this.cause);

  @override
  String toString() => 'DatabaseUnlockException($path): $cause';
}

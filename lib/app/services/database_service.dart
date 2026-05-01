import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as mobile;
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:sqlcipher_library_windows/sqlcipher_library_windows.dart';
import 'package:sqlite3/open.dart' as sqlite_open;

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

    // Users table
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT,
        role TEXT NOT NULL DEFAULT 'user',
        permissions TEXT NOT NULL DEFAULT '[]',
        must_change_password INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Groups table
    batch.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        day_of_week TEXT,
        time TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Group schedules table
    batch.execute('''
      CREATE TABLE group_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        day_of_week TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    // Students table
    batch.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        address TEXT NOT NULL DEFAULT '',
        phone1 TEXT NOT NULL DEFAULT '',
        phone2 TEXT NOT NULL DEFAULT '',
        father_job TEXT NOT NULL DEFAULT '',
        school TEXT NOT NULL DEFAULT '',
        previous_teacher TEXT NOT NULL DEFAULT '',
        group_id INTEGER,
        grade TEXT,
        student_status TEXT NOT NULL DEFAULT 'normal',
        attendance_day TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL
      )
    ''');

    // Payments table
    batch.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        paid_date TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    // Attendance table
    batch.execute('''
      CREATE TABLE attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'attended',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');

    // Assistants table
    batch.execute('''
      CREATE TABLE assistants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Assistant Attendance table
    batch.execute('''
      CREATE TABLE assistant_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assistant_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (assistant_id) REFERENCES assistants(id) ON DELETE CASCADE
      )
    ''');

    // Exams table
    batch.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        full_mark REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Exam groups junction table
    batch.execute('''
      CREATE TABLE exam_groups (
        exam_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        PRIMARY KEY (exam_id, group_id),
        FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');

    // Marks table
    batch.execute('''
      CREATE TABLE marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        score REAL NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        UNIQUE(exam_id, student_id)
      )
    ''');

    // Notes table
    batch.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');

    // Student notes junction table
    batch.execute('''
      CREATE TABLE student_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        note_id INTEGER NOT NULL,
        delivered_date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        UNIQUE(student_id, note_id)
      )
    ''');

    // App settings (key-value store)
    batch.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Device binding
    batch.execute('''
      CREATE TABLE device_binding (
        id INTEGER PRIMARY KEY,
        device_fingerprint TEXT NOT NULL,
        device_name TEXT,
        os_info TEXT,
        bound_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Login attempts
    batch.execute('''
      CREATE TABLE login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 0,
        attempted_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    await batch.commit(noResult: true);

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_students_group ON students(group_id)');
    await db.execute(
      'CREATE INDEX idx_payments_student ON payments(student_id)',
    );
    await db.execute(
      'CREATE INDEX idx_attendance_student ON attendance(student_id)',
    );
    await db.execute('CREATE INDEX idx_attendance_date ON attendance(date)');
    await db.execute('CREATE INDEX idx_marks_exam ON marks(exam_id)');
    await db.execute('CREATE INDEX idx_marks_student ON marks(student_id)');
    await db.execute(
      'CREATE INDEX idx_group_schedules_group ON group_schedules(group_id)',
    );
    await db.execute(
      'CREATE INDEX idx_assistant_attendance_assistant ON assistant_attendance(assistant_id)',
    );
    await db.execute(
      'CREATE INDEX idx_assistant_attendance_date ON assistant_attendance(date)',
    );
    await db.execute(
      'CREATE INDEX idx_login_attempts_username ON login_attempts(username)',
    );
  }

  /// Ensure all required tables exist on every open.
  /// This handles existing databases that were created at an older version.
  Future<void> _onOpen(Database db) async {
    if (kDebugMode) {
      print('Running _onOpen: ensuring all required tables exist...');
    }

    // Tables
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT,
        role TEXT NOT NULL DEFAULT 'user',
        permissions TEXT NOT NULL DEFAULT '[]',
        must_change_password INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        day_of_week TEXT,
        time TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS group_schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        day_of_week TEXT NOT NULL,
        time TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        address TEXT NOT NULL DEFAULT '',
        phone1 TEXT NOT NULL DEFAULT '',
        phone2 TEXT NOT NULL DEFAULT '',
        father_job TEXT NOT NULL DEFAULT '',
        school TEXT NOT NULL DEFAULT '',
        previous_teacher TEXT NOT NULL DEFAULT '',
        group_id INTEGER,
        grade TEXT,
        student_status TEXT NOT NULL DEFAULT 'normal',
        attendance_day TEXT,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL DEFAULT 0,
        paid_date TEXT,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'attended',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serial_number TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        phone TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_attendance (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        assistant_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (assistant_id) REFERENCES assistants(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        full_mark REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exam_groups (
        exam_id INTEGER NOT NULL,
        group_id INTEGER NOT NULL,
        PRIMARY KEY (exam_id, group_id),
        FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS marks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        score REAL NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        UNIQUE(exam_id, student_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        note_id INTEGER NOT NULL,
        delivered_date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
        UNIQUE(student_id, note_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_binding (
        id INTEGER PRIMARY KEY,
        device_fingerprint TEXT NOT NULL,
        device_name TEXT,
        os_info TEXT,
        bound_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS login_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        success INTEGER NOT NULL DEFAULT 0,
        attempted_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
      )
    ''');

    // Ensure columns added in past migrations exist
    try {
      await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE users ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0',
      );
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE students ADD COLUMN grade TEXT');
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE students ADD COLUMN student_status TEXT NOT NULL DEFAULT 'normal'",
      );
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE students ADD COLUMN attendance_day TEXT');
    } catch (_) {}

    // Ensure indexes exist
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_students_group ON students(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_payments_student ON payments(student_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_marks_exam ON marks(exam_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_marks_student ON marks(student_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_group_schedules_group ON group_schedules(group_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_assistant_attendance_assistant ON assistant_attendance(assistant_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_assistant_attendance_date ON assistant_attendance(date)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_login_attempts_username ON login_attempts(username)');
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

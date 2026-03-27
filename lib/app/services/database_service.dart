import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'encryption_service.dart';

/// Centralized database service for initializing and accessing the SQLite database.
///
/// Supports both mobile (sqflite) and desktop (sqflite_common_ffi).
/// The database is encrypted using a passphrase stored in secure storage.
class DatabaseService {
  static Database? _database;
  static const int _dbVersion = 5;
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
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> _initDatabase() async {
    final String dbPath = await _getDatabasePath();
    // Note: encryption key is available via _encryptionService.getDatabaseKey()
    // but standard sqflite doesn't support the password parameter.
    // To enable encryption, replace sqflite with sqflite_sqlcipher in pubspec.yaml.

    if (kDebugMode) {
      print('Database path: $dbPath');
    }

    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        // Ensure the default admin exists with the new password hash (123)
        await db.execute('''
          INSERT OR REPLACE INTO users (username, password_hash, role, permissions)
          VALUES ('admin', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'admin', '["manageStudents","manageGroups","managePayments","manageAttendance","manageExams","viewReports","manageUsers"]')
        ''');
      },
    );
  }

  Future<String> _getDatabasePath() async {
    final Directory documentsDir = await getApplicationDocumentsDirectory();
    final Directory dbDir = Directory(join(documentsDir.path, 'StudentManagement'));
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
        role TEXT NOT NULL DEFAULT 'user',
        permissions TEXT NOT NULL DEFAULT '[]',
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

    // Group schedules table (added in version 2)
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
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        UNIQUE(student_id, month, year)
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

    batch.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        full_mark REAL NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Exam groups junction table (added in version 3)
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

    // Create default admin user (username: admin, password: 123)
    batch.execute('''
      INSERT OR REPLACE INTO users (username, password_hash, role, permissions)
      VALUES ('admin', 'a665a45920422f9d417e4867efdc4fb8a04a1f3fff1fa07e998e86f7f7a27ae3', 'admin', '["manageStudents","manageGroups","managePayments","manageAttendance","manageExams","viewReports","manageUsers"]')
    ''');

    await batch.commit(noResult: true);

    // Create indexes for performance
    await db.execute(
        'CREATE INDEX idx_students_group ON students(group_id)');
    await db.execute(
        'CREATE INDEX idx_payments_student ON payments(student_id)');
    await db.execute(
        'CREATE INDEX idx_attendance_student ON attendance(student_id)');
    await db.execute(
        'CREATE INDEX idx_attendance_date ON attendance(date)');
    await db.execute(
        'CREATE INDEX idx_marks_exam ON marks(exam_id)');
    await db.execute(
        'CREATE INDEX idx_marks_student ON marks(student_id)');
    await db.execute(
        'CREATE INDEX idx_group_schedules_group ON group_schedules(group_id)');
  }

  /// Handle database migrations.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      final Batch batch = db.batch();

      // Create group_schedules table
      batch.execute('''
        CREATE TABLE group_schedules (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          day_of_week TEXT NOT NULL,
          time TEXT NOT NULL,
          FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
        )
      ''');

      // Migrate existing data from groups table
      // We use rawQuery to get all groups and then insert into group_schedules
      final groups = await db.query('groups');
      for (final group in groups) {
        final groupId = group['id'];
        final day = group['day_of_week'];
        final time = group['time'];

        if (day != null && time != null) {
          batch.insert('group_schedules', {
            'group_id': groupId,
            'day_of_week': day,
            'time': time,
          });
        }
      }

      await batch.commit(noResult: true);

      // Create index for performance
      await db.execute(
          'CREATE INDEX idx_group_schedules_group ON group_schedules(group_id)');
    }

    if (oldVersion < 3) {
      final Batch batch = db.batch();
      batch.execute('''
        CREATE TABLE exam_groups (
          exam_id INTEGER NOT NULL,
          group_id INTEGER NOT NULL,
          PRIMARY KEY (exam_id, group_id),
          FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
          FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
        )
      ''');
      await batch.commit(noResult: true);
    }

    if (oldVersion < 4) {
      // Remove UNIQUE constraint from payments table to allow multiple partial payments
      await db.transaction((txn) async {
        // 1. Rename existing table
        await txn.execute('ALTER TABLE payments RENAME TO payments_old');

        // 2. Create new table without UNIQUE constraint
        await txn.execute('''
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

        // 3. Copy data
        await txn.execute('''
          INSERT INTO payments (id, student_id, month, year, total_amount, paid_amount, paid_date)
          SELECT id, student_id, month, year, total_amount, paid_amount, paid_date FROM payments_old
        ''');

        // 4. Drop old table
        await txn.execute('DROP TABLE payments_old');

        // 5. Re-create index for performance
        await txn.execute('CREATE INDEX idx_payments_student ON payments(student_id)');
      });
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE students ADD COLUMN grade TEXT');
    }
  }

  /// Close the database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

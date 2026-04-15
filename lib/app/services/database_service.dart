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
  static const int _dbVersion = 14;
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
          onUpgrade: _onUpgrade,
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
        onUpgrade: _onUpgrade,
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

    // No default admin user — created via first-launch setup wizard

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
        'CREATE INDEX idx_group_schedules_group ON group_schedules(group_id)',
      );
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
        await txn.execute(
          'CREATE INDEX idx_payments_student ON payments(student_id)',
        );
      });
    }

    if (oldVersion < 5) {
      await db.execute('ALTER TABLE students ADD COLUMN grade TEXT');
    }
    if (oldVersion < 6) {
      await db.execute(
        "ALTER TABLE students ADD COLUMN student_status TEXT NOT NULL DEFAULT 'normal'",
      );
    }

    if (oldVersion < 7) {
      await db.execute('ALTER TABLE students ADD COLUMN attendance_day TEXT');
    }

    if (oldVersion < 8) {
      // Normalize grade data in students table
      await db.execute('''
        UPDATE students SET grade = CASE
          WHEN grade IN ('الصف الأول الابتدائي', 'الاول الابتدائي', 'الأول الابتدائي', 'الاول الابتدائى') THEN 'primary_1'
          WHEN grade IN ('الصف الثاني الابتدائي', 'الثاني الابتدائي', 'الثانى الابتدائي', 'الثانى الابتدائى') THEN 'primary_2'
          WHEN grade IN ('الصف الثالث الابتدائي', 'الثالث الابتدائي', 'الثالث الابتدائى') THEN 'primary_3'
          WHEN grade IN ('الصف الرابع الابتدائي', 'الرابع الابتدائي', 'الرابع الابتدائى') THEN 'primary_4'
          WHEN grade IN ('الصف الخامس الابتدائي', 'الخامس الابتدائي', 'الخامس الابتدائى') THEN 'primary_5'
          WHEN grade IN ('الصف السادس الابتدائي', 'السادس الابتدائي', 'السادس الابتدائى') THEN 'primary_6'
          WHEN grade IN ('الصف الأول الإعدادي', 'الاول الاعدادي', 'الاول الاعدادى', 'الأول الإعدادي') THEN 'prep_1'
          WHEN grade IN ('الصف الثاني الإعدادي', 'الثاني الاعدادي', 'الثانى الاعدادى', 'الثاني الإعدادي') THEN 'prep_2'
          WHEN grade IN ('الصف الثالث الإعدادي', 'الثالث الاعدادي', 'الثالث الاعدادى', 'الثالث الإعدادي') THEN 'prep_3'
          WHEN grade IN ('الصف الأول الثانوي', 'الأول الثانوى', 'الأول الثانوي', 'الاول الثانوى', 'الاول الثانوي') THEN 'sec_1'
          WHEN grade IN ('الصف الثاني الثانوي', 'الثانى الثانوى', 'الثاني الثانوى', 'الثاني الثانوي') THEN 'sec_2'
          WHEN grade IN ('الصف الثالث الثانوي', 'الثالث الثانوى', 'الثالث الثانوي') THEN 'sec_3'
          ELSE grade
        END
      ''');
    }

    if (oldVersion < 9) {
      // Normalize attendance day data in students table
      await db.execute('''
        UPDATE students SET attendance_day = CASE
          WHEN attendance_day IN ('الاثنين') THEN 'Monday'
          WHEN attendance_day IN ('الثلاثاء') THEN 'Tuesday'
          WHEN attendance_day IN ('الأربعاء', 'الاربعاء') THEN 'Wednesday'
          WHEN attendance_day IN ('الخميس') THEN 'Thursday'
          WHEN attendance_day IN ('الجمعة') THEN 'Friday'
          WHEN attendance_day IN ('السبت') THEN 'Saturday'
          WHEN attendance_day IN ('الأحد', 'الاحد') THEN 'Sunday'
          ELSE attendance_day
        END
      ''');
    }

    if (oldVersion < 10) {
      // Remove UNIQUE constraint from payments table that might have been created by newer _onCreate
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
        await txn.execute(
          'CREATE INDEX idx_payments_student ON payments(student_id)',
        );
      });
    }

    if (oldVersion < 11) {
      final Batch batch = db.batch();

      batch.execute('''
        CREATE TABLE assistants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          serial_number TEXT NOT NULL UNIQUE,
          name TEXT NOT NULL,
          phone TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');

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

      await batch.commit(noResult: true);
      await db.execute(
        'CREATE INDEX idx_assistant_attendance_assistant ON assistant_attendance(assistant_id)',
      );
      await db.execute(
        'CREATE INDEX idx_assistant_attendance_date ON assistant_attendance(date)',
      );
    }

    if (oldVersion < 12) {
      // Rebuild marks table with UNIQUE constraint on (exam_id, student_id)
      await db.transaction((txn) async {
        // 1. Deduplicate: keep only the latest mark per (exam_id, student_id)
        await txn.execute('''
          DELETE FROM marks WHERE id NOT IN (
            SELECT MAX(id) FROM marks GROUP BY exam_id, student_id
          )
        ''');

        // 2. Rename existing table
        await txn.execute('ALTER TABLE marks RENAME TO marks_old');

        // 3. Create new table with UNIQUE constraint
        await txn.execute('''
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

        // 4. Copy deduplicated data
        await txn.execute('''
          INSERT INTO marks (id, exam_id, student_id, score)
          SELECT id, exam_id, student_id, score FROM marks_old
        ''');

        // 5. Drop old table
        await txn.execute('DROP TABLE marks_old');

        // 6. Re-create indexes
        await txn.execute('CREATE INDEX idx_marks_exam ON marks(exam_id)');
        await txn.execute(
          'CREATE INDEX idx_marks_student ON marks(student_id)',
        );
      });
    }

    if (oldVersion < 13) {
      if (kDebugMode) {
        print(
          'Database Version < 13: Adding notes and student_notes tables...',
        );
      }
      final Batch batch = db.batch();
      batch.execute('''
        CREATE TABLE notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          created_at TEXT NOT NULL DEFAULT (datetime('now'))
        )
      ''');
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
      await batch.commit(noResult: true);
    }

    if (oldVersion < 14) {
      if (kDebugMode) {
        print(
          'Database Version < 14: Adding settings, audit, device binding tables...',
        );
      }
      final Batch batch = db.batch();

      // App Settings (key-value store)
      batch.execute('''
        CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updated_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');

      // Audit Log
      batch.execute('''
        CREATE TABLE audit_log (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER NOT NULL,
          action TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id INTEGER,
          details TEXT,
          created_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
          FOREIGN KEY (user_id) REFERENCES users(id)
        )
      ''');

      // Device Binding
      batch.execute('''
        CREATE TABLE device_binding (
          id INTEGER PRIMARY KEY,
          device_fingerprint TEXT NOT NULL,
          device_name TEXT,
          os_info TEXT,
          bound_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');

      // Login Attempts
      batch.execute('''
        CREATE TABLE login_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL,
          success INTEGER NOT NULL DEFAULT 0,
          attempted_at TEXT NOT NULL DEFAULT (datetime('now', 'localtime'))
        )
      ''');

      await batch.commit(noResult: true);

      // Add salt column to users table
      try {
        await db.execute('ALTER TABLE users ADD COLUMN salt TEXT');
      } catch (_) {
        // Column may already exist
      }

      // Add must_change_password column to users table
      try {
        await db.execute(
          'ALTER TABLE users ADD COLUMN must_change_password INTEGER NOT NULL DEFAULT 0',
        );
      } catch (_) {
        // Column may already exist
      }

      // Create indexes for performance
      await db.execute('CREATE INDEX idx_audit_log_user ON audit_log(user_id)');
      await db.execute(
        'CREATE INDEX idx_audit_log_created ON audit_log(created_at)',
      );
      await db.execute(
        'CREATE INDEX idx_login_attempts_username ON login_attempts(username)',
      );
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

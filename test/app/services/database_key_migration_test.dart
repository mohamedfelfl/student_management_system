@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';

import '../../helpers/memory_secure_storage.dart';
import '../../helpers/sqlcipher_test_factory.dart';

/// The key the old app stored: sha256 of a timestamp, never marked as v2.
const String _legacyKey =
    'ac97ad62dc5f33962deed375a7a578dd712520b872de5077548c4e75e588e024';

void main() {
  final DatabaseFactory factory = sqlcipherTestFactory();

  late Directory dir;
  late String dbPath;
  late MemorySecureStorage storage;
  late DatabaseService service;

  DatabaseService newService() => DatabaseService(
        encryptionService: EncryptionService(secureStorage: storage),
        databasePath: () async => dbPath,
        desktopFactory: factory,
      );

  /// Creates a database at [path] with two students and one payment, either
  /// unencrypted ([key] null) or encrypted with [key].
  Future<void> createDatabase(String path, {String? key}) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onConfigure: (db) async {
          if (key != null) await db.execute("PRAGMA key = '$key'");
        },
      ),
    );
    await db.execute(DBQueries.createGroupsTable);
    await db.execute(DBQueries.createStudentsTable);
    await db.execute(DBQueries.createPaymentsTable);
    await db.insert('students', {'id': 1, 'serial_number': 'EL-01-00001', 'name': 'أحمد'});
    await db.insert('students', {'id': 2, 'serial_number': 'EL-01-00002', 'name': 'منى'});
    await db.insert('payments', {
      'student_id': 1,
      'month': 10,
      'year': 2026,
      'total_amount': 200.0,
      'paid_amount': 150.0,
    });
    await db.close();
  }

  Future<int> countStudents(String path, String key) async {
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute("PRAGMA key = '$key'"),
      ),
    );
    try {
      return (await db.rawQuery('SELECT COUNT(*) AS c FROM students'))
          .first['c'] as int;
    } finally {
      await db.close();
    }
  }

  List<String> fileNames() => dir
      .listSync()
      .map((e) => p.basename(e.path))
      .where((n) => !n.endsWith('-wal') && !n.endsWith('-shm'))
      .toList()
    ..sort();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('db_key_migration_test');
    dbPath = p.join(dir.path, 'student_management.db');
    storage = MemorySecureStorage();
    service = newService();
  });

  tearDown(() async {
    await service.close();
    await dir.delete(recursive: true);
  });

  group('unencrypted database from an older version', () {
    setUp(() async {
      storage.values['sms_db_encryption_key'] = _legacyKey;
      await createDatabase(dbPath);
      expect(isPlaintextSqlite(dbPath), isTrue);
    });

    test('is encrypted on first launch and keeps all its data', () async {
      final db = await service.database;

      expect(await db.query('students'), hasLength(2));
      expect(await db.query('payments'), hasLength(1));
      await service.close();
      expect(isPlaintextSqlite(dbPath), isFalse);
    });

    test('is encrypted with a new random key, not the old stored one', () async {
      await service.database;
      await service.close();

      final String key = storage.values['sms_db_encryption_key']!;
      expect(key, isNot(_legacyKey));
      expect(key, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await countStudents(dbPath, key), 2);
    });

    test('leaves no unencrypted copy on disk', () async {
      await service.database;
      await service.close();

      expect(fileNames(), ['student_management.db']);
    });
  });

  test('a half-written encrypted copy from an interrupted run is discarded',
      () async {
    storage.values['sms_db_encryption_key'] = _legacyKey;
    await createDatabase(dbPath);
    File('$dbPath.encrypting').writeAsStringSync('partial, unusable');

    final db = await service.database;

    expect(await db.query('students'), hasLength(2));
    await service.close();
    expect(isPlaintextSqlite(dbPath), isFalse);
    expect(fileNames(), ['student_management.db']);
  });

  test('a run interrupted while swapping files is completed on next launch',
      () async {
    // State after the verified encrypted copy was made and the original was
    // moved aside, but before the copy took its place.
    final String key = EncryptionService.generateKey();
    storage.values['sms_db_encryption_key'] = key;
    storage.values['sms_db_key_version'] = '2';
    await createDatabase('$dbPath.encrypting', key: key);
    await createDatabase('$dbPath.plaintext-2026-10-22T10-00-00');

    final db = await service.database;

    expect(await db.query('students'), hasLength(2));
    await service.close();
    expect(fileNames(), ['student_management.db']);
  });

  group('database encrypted with an old-style key', () {
    setUp(() async {
      storage.values['sms_db_encryption_key'] = _legacyKey;
      await createDatabase(dbPath, key: _legacyKey);
    });

    test('is re-keyed to a new random key and keeps its data', () async {
      final db = await service.database;
      expect(await db.query('students'), hasLength(2));
      await service.close();

      final String newKey = storage.values['sms_db_encryption_key']!;
      expect(newKey, isNot(_legacyKey));
      expect(newKey, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(await countStudents(dbPath, newKey), 2);
      await expectLater(countStudents(dbPath, _legacyKey), throwsA(anything));
    });

    test('is not re-keyed again on the next launch', () async {
      await service.database;
      await service.close();
      final String keyAfterFirstLaunch = storage.values['sms_db_encryption_key']!;

      await newService().database;

      expect(storage.values['sms_db_encryption_key'], keyAfterFirstLaunch);
    });
  });

  test('opens a database whose re-key finished before the new key was saved',
      () async {
    final String newKey = EncryptionService.generateKey();
    storage.values['sms_db_encryption_key'] = _legacyKey;
    storage.values['sms_db_encryption_key_pending'] = newKey;
    await createDatabase(dbPath, key: newKey);

    final db = await service.database;

    expect(await db.query('students'), hasLength(2));
    expect(storage.values['sms_db_encryption_key'], newKey);
    expect(storage.values.containsKey('sms_db_encryption_key_pending'), isFalse);
  });
}

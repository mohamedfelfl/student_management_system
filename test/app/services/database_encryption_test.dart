@TestOn('windows')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';

import '../../helpers/memory_secure_storage.dart';
import '../../helpers/sqlcipher_test_factory.dart';

void main() {
  late Directory dir;
  late String dbPath;
  late DatabaseService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('db_encryption_test');
    dbPath = p.join(dir.path, 'student_management.db');
  });

  tearDown(() async {
    await service.close();
    await dir.delete(recursive: true);
  });

  test('student data written by the app is encrypted on disk', () async {
    service = DatabaseService(
      encryptionService: EncryptionService(secureStorage: MemorySecureStorage()),
      databasePath: () async => dbPath,
      desktopFactory: sqlcipherTestFactory(),
    );

    final db = await service.database;
    await db.insert('students', {
      'serial_number': 'EL-01-00001',
      'name': 'Confidential Student Name',
      'phone1': '01012345678',
    });
    await service.close();

    expect(isPlaintextSqlite(dbPath), isFalse);
    final bytes = File(dbPath).readAsBytesSync();
    final raw = latin1.decode(bytes, allowInvalid: true);
    expect(raw.contains('Confidential Student Name'), isFalse);
    expect(raw.contains('01012345678'), isFalse);
  });

  test('refuses to open the database when SQLCipher is not loaded', () async {
    service = DatabaseService(
      encryptionService: EncryptionService(secureStorage: MemorySecureStorage()),
      databasePath: () async => dbPath,
      // Plain SQLite: PRAGMA key would be silently ignored.
      desktopFactory: createDatabaseFactoryFfi(noIsolate: true),
    );

    await expectLater(
      service.database,
      throwsA(isA<DatabaseEncryptionUnavailableException>()),
    );
  });
}

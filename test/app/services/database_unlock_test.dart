import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';

class _FixedKeyEncryptionService extends EncryptionService {
  @override
  Future<String> getDatabaseKey() async => 'test-key';
}

/// Bytes that are not a SQLite database: what SQLCipher sees when the file is
/// opened with the wrong key.
final List<int> _unreadableBytes = List<int>.generate(4096, (i) => (i * 7) % 251);

void main() {
  sqfliteFfiInit();

  late Directory dir;
  late String dbPath;
  late DatabaseService service;

  List<String> fileNames() =>
      dir.listSync().map((e) => p.basename(e.path)).toList()..sort();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('db_unlock_test');
    dbPath = p.join(dir.path, 'student_management.db');
    service = DatabaseService(
      encryptionService: _FixedKeyEncryptionService(),
      databasePath: () async => dbPath,
    );
  });

  tearDown(() async {
    await service.close();
    await dir.delete(recursive: true);
  });

  test('an unreadable database is reported and left untouched', () async {
    File(dbPath).writeAsBytesSync(_unreadableBytes);

    await expectLater(
      service.database,
      throwsA(isA<DatabaseUnlockException>()),
    );

    expect(File(dbPath).readAsBytesSync(), _unreadableBytes);
    expect(fileNames(), ['student_management.db']);
  });

  test('starting fresh keeps every unreadable file under its own name',
      () async {
    File(dbPath).writeAsBytesSync(_unreadableBytes);
    await expectLater(service.database, throwsA(isA<DatabaseUnlockException>()));
    final first = await service.quarantineDatabaseAndStartFresh();

    File(dbPath).writeAsBytesSync(_unreadableBytes.reversed.toList());
    final second = await service.quarantineDatabaseAndStartFresh();

    expect(first, isNot(second));
    expect(File(first).readAsBytesSync(), _unreadableBytes);
    expect(File(second).readAsBytesSync(), _unreadableBytes.reversed.toList());

    final db = await service.database;
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'students'",
    );
    expect(tables, hasLength(1));
  });

  test('verifyCanOpen rejects a file that cannot be unlocked', () async {
    final candidate = p.join(dir.path, 'other_device_backup.db');
    File(candidate).writeAsBytesSync(_unreadableBytes);

    await expectLater(
      service.verifyCanOpen(candidate),
      throwsA(isA<DatabaseUnlockException>()),
    );
  });

  test('verifyCanOpen rejects a readable database that is not an app database',
      () async {
    final candidate = p.join(dir.path, 'some_other_app.db');
    final other = await databaseFactoryFfi.openDatabase(candidate);
    await other.execute('CREATE TABLE notes_of_another_app (id INTEGER)');
    await other.close();

    await expectLater(
      service.verifyCanOpen(candidate),
      throwsA(isA<DatabaseUnlockException>()),
    );
  });

  test('verifyCanOpen accepts a database created by this app', () async {
    await service.database;
    await service.close();

    await service.verifyCanOpen(dbPath);
  });
}

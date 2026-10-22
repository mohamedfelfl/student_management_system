@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/settings/services/backup_service.dart';

import '../../helpers/memory_secure_storage.dart';
import '../../helpers/sqlcipher_test_factory.dart';

void main() {
  final factory = sqlcipherTestFactory();

  late Directory root;
  late String dbPath;
  late DatabaseService databaseService;
  late BackupService backupService;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('restore_test');
    final appDir = Directory(p.join(root.path, 'StudentManagement'))
      ..createSync(recursive: true);
    dbPath = p.join(appDir.path, 'student_management.db');
    databaseService = DatabaseService(
      encryptionService: EncryptionService(secureStorage: MemorySecureStorage()),
      databasePath: () async => dbPath,
      desktopFactory: factory,
    );
    backupService = BackupService(
      databaseService: databaseService,
      documentsDirectory: () async => root,
    );

    // A real, working database with one student.
    final db = await databaseService.database;
    await db.insert('students', {'serial_number': 'EL-01-00001', 'name': 'أحمد'});
    await databaseService.close();
  });

  tearDown(() async {
    await databaseService.close();
    await root.delete(recursive: true);
  });

  test('a backup taken by an older (unencrypted) version can still be restored',
      () async {
    final oldBackup = p.join(root.path, 'backup_from_v1_0_5.db');
    final plain = await factory.openDatabase(oldBackup);
    await plain.execute(DBQueries.createGroupsTable);
    await plain.execute(DBQueries.createStudentsTable);
    await plain.insert('students', {'serial_number': 'EL-01-00001', 'name': 'أحمد'});
    await plain.insert('students', {'serial_number': 'EL-01-00002', 'name': 'منى'});
    await plain.close();

    await backupService.restoreFromBackup(oldBackup);

    expect(isPlaintextSqlite(dbPath), isFalse);
    final db = await databaseService.database;
    expect(await db.query('students'), hasLength(2));
  });

  test('restoring a backup this device cannot unlock keeps the current data',
      () async {
    final before = File(dbPath).readAsBytesSync();
    final foreign = File(p.join(root.path, 'from_other_pc.db'))
      ..writeAsBytesSync(List<int>.generate(4096, (i) => (i * 7) % 251));

    await expectLater(
      backupService.restoreFromBackup(foreign.path),
      throwsA(isA<DatabaseUnlockException>()),
    );

    expect(File(dbPath).readAsBytesSync(), before);
    final db = await databaseService.database;
    expect(await db.query('students'), hasLength(1));
  });
}

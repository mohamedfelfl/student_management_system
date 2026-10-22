import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/settings/services/backup_service.dart';

class _FixedKeyEncryptionService extends EncryptionService {
  @override
  Future<String> getDatabaseKey() async => 'test-key';
}

void main() {
  sqfliteFfiInit();

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
      encryptionService: _FixedKeyEncryptionService(),
      databasePath: () async => dbPath,
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

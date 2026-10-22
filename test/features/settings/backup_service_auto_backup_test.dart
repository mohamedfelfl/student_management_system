import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/settings/services/backup_service.dart';

void main() {
  late Directory root;
  late Directory backupsDir;
  late BackupService service;

  List<String> autoBackupNames() => backupsDir
      .listSync()
      .whereType<File>()
      .map((f) => p.basename(f.path))
      .where((n) => n.startsWith('auto_backup'))
      .toList()
    ..sort();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('backup_test');
    final appDir = Directory(p.join(root.path, 'StudentManagement'))
      ..createSync(recursive: true);
    File(p.join(appDir.path, 'student_management.db'))
        .writeAsStringSync('db-contents');
    backupsDir = Directory(p.join(appDir.path, 'Backups'))..createSync();

    service = BackupService(
      databaseService: DatabaseService(encryptionService: EncryptionService()),
      documentsDirectory: () async => root,
    );
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('each automatic backup is a new file', () async {
    await service.createAutoBackup(keep: 5);
    await service.createAutoBackup(keep: 5);

    expect(autoBackupNames(), hasLength(2));
  });

  test('keeps only the newest automatic backups', () async {
    for (int day = 1; day <= 6; day++) {
      File(p.join(backupsDir.path, 'auto_backup_2020-01-0${day}T00-00-00-000000.db'))
          .writeAsStringSync('old $day');
    }

    final created = await service.createAutoBackup(keep: 5);

    final names = autoBackupNames();
    expect(names, hasLength(5));
    expect(names, contains(p.basename(created)));
    expect(names, isNot(contains('auto_backup_2020-01-01T00-00-00-000000.db')));
    expect(names, isNot(contains('auto_backup_2020-01-02T00-00-00-000000.db')));
  });

  test('automatic pruning never deletes manual backups', () async {
    final manual = File(p.join(backupsDir.path, 'backup_before_exam.db'))
      ..writeAsStringSync('manual');
    for (int day = 1; day <= 6; day++) {
      File(p.join(backupsDir.path, 'auto_backup_2020-01-0${day}T00-00-00-000000.db'))
          .writeAsStringSync('old $day');
    }

    await service.createAutoBackup(keep: 2);

    expect(manual.existsSync(), isTrue);
  });
}

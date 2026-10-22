import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/settings/cubits/settings_cubit.dart';
import 'package:student_management_system/features/settings/services/backup_service.dart';
import 'package:student_management_system/features/settings/services/device_binding_service.dart';
import 'package:student_management_system/features/settings/services/settings_service.dart';

/// A manual backup is something the user made on purpose: taking another one
/// must never delete it. Only automatic backups are limited to the newest N.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory backupsDir;
  late SettingsCubit cubit;

  File addBackup(String name, DateTime modified) =>
      File(p.join(backupsDir.path, name))
        ..writeAsStringSync('old backup')
        ..setLastModifiedSync(modified);

  Set<String> backupNames() => backupsDir
      .listSync()
      .whereType<File>()
      .map((f) => p.basename(f.path))
      .toSet();

  setUp(() async {
    root = await Directory.systemTemp.createTemp('manual_backup_test');
    final appDir = Directory(p.join(root.path, 'StudentManagement'))
      ..createSync(recursive: true);
    File(p.join(appDir.path, 'student_management.db'))
        .writeAsStringSync('db-contents');
    backupsDir = Directory(p.join(appDir.path, 'Backups'))..createSync();

    final dbService = DatabaseService(
      encryptionService: EncryptionService(),
      databasePath: () async => p.join(appDir.path, 'student_management.db'),
    );
    cubit = SettingsCubit(
      settingsService: SettingsService(databaseService: dbService),
      backupService: BackupService(
        databaseService: dbService,
        documentsDirectory: () async => root,
      ),
      deviceBindingService: DeviceBindingService(),
    );
  });

  tearDown(() async {
    await cubit.close();
    await root.delete(recursive: true);
  });

  test('a manual backup keeps every older backup, beyond the automatic limit',
      () async {
    // More manual backups than the "keep last N" setting (5 by default).
    for (int day = 1; day <= 6; day++) {
      addBackup('backup_2026-01-0${day}T10-00-00-000000.db', DateTime(2026, 1, day));
    }
    addBackup('auto_backup_2026-02-01T10-00-00-000000.db', DateTime(2026, 2, 1));
    addBackup('auto_backup_2026-02-02T10-00-00-000000.db', DateTime(2026, 2, 2));
    final Set<String> before = backupNames();
    expect(cubit.state.maxBackups, lessThan(before.length));

    await cubit.createBackup();

    expect(cubit.state.errorMessage, isNull);
    final Set<String> after = backupNames();
    expect(after, containsAll(before));
    expect(after.difference(before), hasLength(1),
        reason: 'the new manual backup is added');
    expect(cubit.state.backups, hasLength(before.length + 1));
  });
}

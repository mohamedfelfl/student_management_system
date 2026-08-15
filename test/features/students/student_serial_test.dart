import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

class TestDatabaseService extends DatabaseService {
  final Database _testDb;
  TestDatabaseService(this._testDb)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _testDb;
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Student Serial Number Auto-Increment Tests', () {
    late Database db;
    late StudentCubit cubit;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute(DBQueries.createStudentsTable);
      await db.execute(DBQueries.createAppSettingsTable);
      cubit = StudentCubit(databaseService: TestDatabaseService(db));
    });

    tearDown(() async {
      await cubit.close();
      await db.close();
    });

    test('Returns starting base 10777 for prep_1 on empty database', () async {
      final serial = await cubit.getNextSerialNumber('prep_1');
      expect(serial, '10777');
    });

    test('Increments sequentially as prep_1 students are added', () async {
      expect(await cubit.getNextSerialNumber('prep_1'), '10777');

      final assigned1 = await cubit.createStudent({
        'serial_number': '10777',
        'name': 'Student 1',
        'grade': 'prep_1',
      });
      expect(assigned1, '10777');
      expect(await cubit.getNextSerialNumber('prep_1'), '10778');

      final assigned2 = await cubit.createStudent({
        'serial_number': '10778',
        'name': 'Student 2',
        'grade': 'prep_1',
      });
      expect(assigned2, '10778');
      expect(await cubit.getNextSerialNumber('prep_1'), '10779');

      final assigned3 = await cubit.createStudent({
        'serial_number': '10779',
        'name': 'Student 3',
        'grade': 'prep_1',
      });
      expect(assigned3, '10779');
      expect(await cubit.getNextSerialNumber('prep_1'), '10780');
    });

    test('Calculates distinct independent base ranges for all grades', () async {
      expect(await cubit.getNextSerialNumber('prep_1'), '10777');
      expect(await cubit.getNextSerialNumber('prep_2'), '20777');
      expect(await cubit.getNextSerialNumber('prep_3'), '30777');
      expect(await cubit.getNextSerialNumber('sec_1'), '40777');
      expect(await cubit.getNextSerialNumber('sec_2'), '50777');
      expect(await cubit.getNextSerialNumber('sec_3'), '60777');

      await cubit.createStudent({
        'serial_number': '20777',
        'name': 'Prep 2 Student 1',
        'grade': 'prep_2',
      });

      // prep_2 increments, while prep_1 remains at base
      expect(await cubit.getNextSerialNumber('prep_2'), '20778');
      expect(await cubit.getNextSerialNumber('prep_1'), '10777');
    });

    test('Avoids duplicate collisions when legacy or global serial exists', () async {
      await cubit.createStudent({
        'serial_number': '10777',
        'name': 'Existing Student',
        'grade': 'prep_1',
      });
      await cubit.createStudent({
        'serial_number': '10778',
        'name': 'Existing Student 2',
        'grade': 'prep_2', // Even if in another grade
      });

      // Should automatically skip 10778 and advance to 10779
      expect(await cubit.getNextSerialNumber('prep_1'), '10779');
    });

    test('createStudent automatically resolves conflicts when duplicate serial is submitted', () async {
      // First student gets 10777
      await cubit.createStudent({
        'serial_number': '10777',
        'name': 'Original Student',
        'grade': 'prep_1',
      });

      // Second student attempts to submit 10777 (e.g. stale form / race condition)
      final resolvedSerial = await cubit.createStudent({
        'serial_number': '10777',
        'name': 'Concurrent Student',
        'grade': 'prep_1',
      });

      // Automatically resolved to 10778 without UNIQUE constraint crash!
      expect(resolvedSerial, '10778');
      expect(await cubit.getNextSerialNumber('prep_1'), '10779');
    });
  });
}

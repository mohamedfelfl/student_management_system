import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

  group('DatabaseService startup (app restart) data safety', () {
    late Database db;
    late TestDatabaseService dbService;
    late StudentCubit cubit;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute('PRAGMA foreign_keys = ON');
      dbService = TestDatabaseService(db);
      // First launch: builds the schema exactly as the app does.
      await dbService.runOnOpenForTesting(db);
      cubit = StudentCubit(databaseService: dbService);
    });

    tearDown(() async {
      await cubit.close();
      await db.close();
    });

    test(
      'keeps a newly added student whose name matches an existing one after restart',
      () async {
        await cubit.createStudent({'name': 'محمد أحمد', 'grade': 'sec_1'});
        // The add-student form lets the user confirm "proceed anyway" for a
        // same-name student (e.g. a different person with a common name).
        final secondSerial = await cubit.createStudent(
          {'name': 'محمد احمد', 'grade': 'sec_1'},
          allowDuplicateName: true,
        );
        final second = (await db.query(
          'students',
          where: 'serial_number = ?',
          whereArgs: [secondSerial],
        ))
            .single;
        await db.insert('payments', {
          'student_id': second['id'],
          'month': 10,
          'year': 2026,
          'total_amount': 200,
          'paid_amount': 200,
        });

        // Simulate closing and reopening the app.
        await dbService.runOnOpenForTesting(db);

        final students = await db.query('students', orderBy: 'id');
        expect(students.map((s) => s['name']), ['محمد أحمد', 'محمد احمد']);
        expect(
          await cubit.getStudentBySerial(secondSerial),
          isNotNull,
          reason: 'printed QR card of the second student must still resolve',
        );
        expect(
          await db.query(
            'payments',
            where: 'student_id = ?',
            whereArgs: [second['id']],
          ),
          hasLength(1),
          reason: 'payments of the second student must not be cascaded away',
        );
      },
    );

    test('keeps students whose names differ only by hamza/taa marbuta', () async {
      await cubit.createStudent({'name': 'فاطمة علي', 'grade': 'sec_2'});
      await cubit.createStudent({'name': 'فاطمه علي', 'grade': 'sec_2'});

      await dbService.runOnOpenForTesting(db);

      expect(await db.query('students'), hasLength(2));
    });
  });
}

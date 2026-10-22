import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

/// The student list filters by grade on screen only, so "select all" and bulk
/// delete must work on the students the user can actually see.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late StudentCubit cubit;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(DBQueries.createGroupsTable);
    await db.execute(DBQueries.createStudentsTable);
    await db.insert('students', {'id': 1, 'serial_number': 'EL-01-00001', 'name': 'أ', 'grade': 'sec_1'});
    await db.insert('students', {'id': 2, 'serial_number': 'EL-01-00002', 'name': 'ب', 'grade': 'sec_1'});
    await db.insert('students', {'id': 3, 'serial_number': 'EL-02-00001', 'name': 'ج', 'grade': 'sec_2'});
    cubit = StudentCubit(databaseService: _TestDatabaseService(db));
    await cubit.loadStudents();
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('select all selects only the visible students', () {
    cubit.toggleAll({1, 2});

    expect(cubit.state.selectedIds, {1, 2});
  });

  test('select all a second time clears the selection', () {
    cubit.toggleAll({1, 2});
    cubit.toggleAll({1, 2});

    expect(cubit.state.selectedIds, isEmpty);
  });

  test('select all drops students hidden by a new filter', () {
    cubit.toggleSelection(3);

    cubit.toggleAll({1, 2});

    expect(cubit.state.selectedIds, {1, 2});
  });

  test('changing the filter keeps only selections that are still visible', () {
    cubit.toggleSelection(1);
    cubit.toggleSelection(3);

    cubit.retainSelection({1, 2});

    expect(cubit.state.selectedIds, {1});
  });
}

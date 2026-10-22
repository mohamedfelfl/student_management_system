import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/di/injection.dart';
import 'package:student_management_system/app/services/data_migration_service.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/groups/cubits/group_cubit.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

/// Records every call made to the migration service, whatever the method.
class _SpyMigrationService implements DataMigrationService {
  final List<Symbol> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation.memberName);
    return Future<MigrationResult?>.value(null);
  }
}

/// Importing from an external database must only happen when the user asks
/// for it in Settings, never as a side effect of opening a list.
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late _SpyMigrationService spy;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(DBQueries.createGroupsTable);
    await db.execute(DBQueries.createGroupSchedulesTable);
    await db.execute(DBQueries.createStudentsTable);
    await db.execute(DBQueries.createPaymentsTable);
    await db.execute(DBQueries.createLessonsTable);
    await db.execute(DBQueries.createAttendanceTable);
    spy = _SpyMigrationService();
    getIt.registerSingleton<DataMigrationService>(spy);
  });

  tearDown(() async {
    await getIt.unregister<DataMigrationService>();
    await db.close();
  });

  test('loading an empty student list does not start an import', () async {
    final cubit = StudentCubit(databaseService: _TestDatabaseService(db));

    await cubit.loadStudents();

    expect(spy.calls, isEmpty);
    await cubit.close();
  });

  test('loading an empty group list does not start an import', () async {
    final cubit = GroupCubit(databaseService: _TestDatabaseService(db));

    await cubit.loadGroups();

    expect(spy.calls, isEmpty);
    await cubit.close();
  });
}

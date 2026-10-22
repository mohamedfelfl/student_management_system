import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/reports/cubits/report_cubit.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

/// Simulates a center PC with no internet connection.
class _OfflineHttpOverrides extends HttpOverrides {
  int connectionAttempts = 0;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    connectionAttempts++;
    throw const SocketException('No internet connection (test)');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late ReportCubit cubit;

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(DBQueries.createGroupsTable);
    await db.execute(DBQueries.createStudentsTable);
    await db.execute(DBQueries.createExamsTable);
    await db.execute(DBQueries.createMarksTable);
    await db.insert('groups', {'id': 1, 'name': 'السبت'});
    await db.insert('students', {'id': 1, 'serial_number': 'EL-01-00001', 'name': 'أحمد', 'group_id': 1});
    await db.insert('exams', {'id': 1, 'name': 'شهر أكتوبر', 'full_mark': 20.0, 'date': '2026-10-01'});
    await db.insert('marks', {'exam_id': 1, 'student_id': 1, 'score': 18.0});
    cubit = ReportCubit(databaseService: _TestDatabaseService(db));
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  test('a PDF report is generated without an internet connection', () async {
    final offline = _OfflineHttpOverrides();

    await HttpOverrides.runZoned(
      () => cubit.generateHighestMarksReport(examId: 1),
      createHttpClient: offline.createHttpClient,
    );

    expect(cubit.state.error, isNull);
    expect(cubit.state.pdfDocument, isNotNull);
    expect(offline.connectionAttempts, 0);
  });
}

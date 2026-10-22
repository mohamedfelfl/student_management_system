import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/attendance/cubits/attendance_cubit.dart';
import 'package:student_management_system/features/attendance/cubits/lesson_cubit.dart';
import 'package:student_management_system/features/attendance/models/lesson.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

class TestDatabaseService extends DatabaseService {
  final Database _testDb;
  TestDatabaseService(this._testDb)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _testDb;
}

const Lesson _scheduledLesson = Lesson(
  groupId: 1,
  date: '2026-08-29',
  startTime: '10:00',
  title: 'الدرس الأول',
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Card scans resolve to exactly one student', () {
    late Database db;
    late LessonCubit lessonCubit;
    late AttendanceCubit attendanceCubit;
    late StudentCubit studentCubit;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute(DBQueries.createGroupsTable);
      await db.execute(DBQueries.createGroupSchedulesTable);
      await db.execute(DBQueries.createStudentsTable);
      await db.execute(DBQueries.createLessonsTable);
      await db.execute(DBQueries.createAttendanceTable);

      final dbService = TestDatabaseService(db);
      lessonCubit = LessonCubit(databaseService: dbService);
      attendanceCubit = AttendanceCubit(databaseService: dbService);
      studentCubit = StudentCubit(databaseService: dbService);

      await db.insert('groups', {
        'id': 1,
        'name': 'مجموعة السبت 10 صباحاً',
        'grade': 'prep_1',
      });
      // A numeric serial and an imported prefixed serial that contains it.
      await db.insert('students', {
        'id': 1,
        'serial_number': '10777',
        'name': 'طالب الرقم',
        'group_id': 1,
        'grade': 'prep_1',
      });
      await db.insert('students', {
        'id': 2,
        'serial_number': 'EM-10777',
        'name': 'طالب الكارت',
        'group_id': 1,
        'grade': 'prep_1',
      });
    });

    tearDown(() async {
      await lessonCubit.close();
      await attendanceCubit.close();
      await studentCubit.close();
      await db.close();
    });

    test('LessonCubit records the student whose serial matches the card exactly', () async {
      await lessonCubit.startLesson(_scheduledLesson);
      await lessonCubit.recordScanInActiveLesson('EM-10777');

      expect(lessonCubit.state.scanSuccess, isTrue);
      expect(lessonCubit.state.lastScannedStudent, equals('طالب الكارت'));
      final attendance = await db.query('attendance');
      expect(attendance.map((a) => a['student_id']), [2]);
    });

    test('AttendanceCubit records the student whose serial matches the card exactly', () async {
      await attendanceCubit.recordAttendanceBySerial('EM-10777');

      expect(attendanceCubit.state.scanSuccess, isTrue);
      expect(attendanceCubit.state.lastScannedStudent, equals('طالب الكارت'));
      final attendance = await db.query('attendance');
      expect(attendance.map((a) => a['student_id']), [2]);
    });

    test('a card holding only the numeric serial still resolves', () async {
      final student = await studentCubit.getStudentBySerial('10777');
      expect(student!['id'], equals(1));

      await attendanceCubit.recordAttendanceBySerial('10777');
      final attendance = await db.query('attendance');
      expect(attendance.map((a) => a['student_id']), [1]);
    });

    test('records nothing when the scan matches several students but none exactly', () async {
      await db.insert('students', {
        'id': 3,
        'serial_number': '40777',
        'name': 'طالب أول ثانوي',
        'group_id': 1,
        'grade': 'sec_1',
      });
      await db.insert('students', {
        'id': 4,
        'serial_number': '50777',
        'name': 'طالب ثاني ثانوي',
        'group_id': 1,
        'grade': 'sec_2',
      });
      const ambiguousScan = 'EM-40777-50777';

      await lessonCubit.startLesson(_scheduledLesson);
      await lessonCubit.recordScanInActiveLesson(ambiguousScan);
      expect(lessonCubit.state.scanSuccess, isFalse);
      expect(lessonCubit.state.error, isNotNull);
      expect(await db.query('attendance'), isEmpty);

      await attendanceCubit.recordAttendanceBySerial(ambiguousScan);
      expect(attendanceCubit.state.scanSuccess, isFalse);
      expect(await db.query('attendance'), isEmpty);

      expect(await studentCubit.getStudentBySerial(ambiguousScan), isNull);
    });
  });
}

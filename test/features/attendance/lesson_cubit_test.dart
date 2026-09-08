import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/attendance/cubits/lesson_cubit.dart';
import 'package:student_management_system/features/attendance/models/attendance.dart';
import 'package:student_management_system/features/attendance/models/lesson.dart';

void main() {
  group('Lesson Model Tests', () {
    test('Lesson default values and copyWith maintain state', () {
      const lesson = Lesson(
        groupId: 1,
        date: '2026-08-25',
        startTime: '16:00',
      );

      expect(lesson.id, isNull);
      expect(lesson.groupId, equals(1));
      expect(lesson.status, equals(LessonStatus.scheduled));
      expect(lesson.enrolledCount, equals(0));
      expect(lesson.attendedCount, equals(0));

      final active = lesson.copyWith(
        id: 42,
        status: LessonStatus.inProgress,
        attendedCount: 15,
      );

      expect(active.id, equals(42));
      expect(active.status, equals(LessonStatus.inProgress));
      expect(active.attendedCount, equals(15));
    });

    test('Lesson JSON serialization works correctly', () {
      final json = {
        'id': 10,
        'groupId': 2,
        'date': '2026-08-25',
        'startTime': '18:00',
        'title': 'Revision',
        'status': 'inProgress',
      };

      final lesson = Lesson.fromJson(json);
      expect(lesson.id, equals(10));
      expect(lesson.groupId, equals(2));
      expect(lesson.status, equals(LessonStatus.inProgress));
      expect(lesson.title, equals('Revision'));
    });
  });

  group('Attendance Model Tests', () {
    test('Attendance model holds lessonId and groupName', () {
      final attendance = Attendance(
        id: 1,
        lessonId: 5,
        studentId: 101,
        date: DateTime.parse('2026-08-25'),
        status: AttendanceStatus.attended,
        studentName: 'Ahmed Ali',
        serialNumber: 'SN-001',
        groupName: 'Grade 10 Sunday',
      );

      expect(attendance.lessonId, equals(5));
      expect(attendance.status, equals(AttendanceStatus.attended));
      expect(attendance.studentName, equals('Ahmed Ali'));
    });
  });

  group('Lesson Database Persistence Tests', () {
    test('startLesson inserts created_at and survives strict NOT NULL constraint without default', () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      // Simulate strict schema with created_at NOT NULL and NO DEFAULT VALUE
      await db.execute('''
        CREATE TABLE lessons (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          date TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT,
          title TEXT NOT NULL DEFAULT '',
          status TEXT NOT NULL DEFAULT 'scheduled',
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute(DBQueries.createGroupsTable);
      await db.execute(DBQueries.createGroupSchedulesTable);
      await db.execute(DBQueries.createStudentsTable);
      await db.execute(DBQueries.createAttendanceTable);

      final cubit = LessonCubit(databaseService: _MockDatabaseService(db));

      const lesson = Lesson(
        groupId: 1,
        date: '2026-09-08',
        startTime: '10:00 AM',
        title: 'Physics Revision',
      );

      await cubit.startLesson(lesson);

      expect(cubit.state.error, isNull);
      expect(cubit.state.activeLesson, isNotNull);
      expect(cubit.state.activeLesson!.status, equals(LessonStatus.inProgress));

      final rows = await db.query(DBQueries.tableLessons);
      expect(rows.length, equals(1));
      expect(rows.first['created_at'], isNotNull);
      expect((rows.first['created_at'] as String).isNotEmpty, isTrue);

      // Also verify createAdHocLesson
      await cubit.createAdHocLesson(
        groupId: 1,
        date: DateTime(2026, 9, 8),
        startTime: '12:00 PM',
        title: 'Ad-hoc Extra Class',
      );

      expect(cubit.state.error, isNull);
      final rowsAfterAdHoc = await db.query(DBQueries.tableLessons);
      expect(rowsAfterAdHoc.length, equals(2));
      expect(rowsAfterAdHoc[1]['created_at'], isNotNull);

      await cubit.close();
      await db.close();
    });
  });
}

class _MockDatabaseService extends DatabaseService {
  final Database _db;
  _MockDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

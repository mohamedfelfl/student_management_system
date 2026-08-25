import 'package:flutter_test/flutter_test.dart';
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
}

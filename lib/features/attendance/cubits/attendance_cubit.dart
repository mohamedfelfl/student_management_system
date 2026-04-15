import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../../../generated/locale_keys.g.dart';

import '../../../app/services/database_service.dart';
import '../models/attendance.dart';

part 'attendance_cubit.freezed.dart';

@freezed
abstract class AttendanceState with _$AttendanceState {
  const factory AttendanceState({
    @Default([]) List<Map<String, dynamic>> records,
    @Default(false) bool isLoading,
    @Default(false) bool scanSuccess,
    String? lastScannedStudent,
    String? error,
  }) = _AttendanceState;
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final DatabaseService _databaseService;

  AttendanceCubit({required DatabaseService databaseService})
    : _databaseService = databaseService,
      super(const AttendanceState());

  /// Load attendance records for a student.
  Future<void> loadAttendance(int studentId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery(
        '''
        SELECT a.*, s.name as student_name 
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        WHERE a.student_id = ?
        ORDER BY a.date DESC, a.id DESC
      ''',
        [studentId],
      );
      emit(state.copyWith(records: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Load all attendance globally.
  Future<void> loadAllAttendance() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery('''
        SELECT a.*, s.name as student_name 
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        ORDER BY a.date DESC, a.id DESC
      ''');
      emit(state.copyWith(records: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Load recent global scans for the scanner screen.
  Future<void> loadRecentScans() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> latestRecords = await db.rawQuery('''
        SELECT a.*, s.name as student_name 
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        ORDER BY a.id DESC LIMIT 5
      ''');
      emit(state.copyWith(records: latestRecords));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Record attendance via QR scan or manual ID entry.
  /// [serialNumber] is the student's serial number from the QR code.
  Future<void> recordAttendanceBySerial(
    String serialNumber, {
    AttendanceStatus status = AttendanceStatus.attended,
    String notes = '',
  }) async {
    try {
      final Database db = await _databaseService.database;

      // Find student by serial number
      final List<Map<String, Object?>> students = await db.query(
        'students',
        where: 'serial_number = ?',
        whereArgs: <Object?>[serialNumber],
      );

      if (students.isEmpty) {
        emit(
          state.copyWith(
            error: 'Student not found with serial: $serialNumber',
            scanSuccess: false,
          ),
        );
        return;
      }

      final Map<String, Object?> student = students.first;
      final int studentId = student['id'] as int;
      final String studentName = student['name'] as String;
      final int? groupId = student['group_id'] as int?;
      final now = DateTime.now();
      final String currentDayName = DateFormat('EEEE', 'en_US').format(now);
      final String currentDayNameAr = _getArabicDayName(currentDayName);
      final String currentDayNameArAlt = currentDayNameAr
          .replaceAll('أ', 'ا')
          .replaceAll('إ', 'ا');
      final String today = now.toIso8601String().split('T').first;

      // Determine attendance type based on group schedule
      AttendanceStatus finalStatus = status;
      String notesToInsert = notes;

      if (groupId != null) {
        // Get the student's own group schedule days
        final List<Map<String, Object?>> groupSchedules = await db.query(
          'group_schedules',
          where: 'group_id = ?',
          whereArgs: [groupId],
        );

        final bool isStudentGroupDay = groupSchedules.any((s) {
          final day = s['day_of_week']?.toString() ?? '';
          return day == currentDayName ||
              day == currentDayNameAr ||
              day == currentDayNameArAlt;
        });

        if (isStudentGroupDay) {
          // Case 1: Today is one of the student's group scheduled days
          // → "attended in his group"
          finalStatus = AttendanceStatus.attended;
          notesToInsert = LocaleKeys.attended_his_group.tr();
        } else {
          // Case 2: Today is NOT the student's group day
          // → Find which group meets today closest to current time
          finalStatus = AttendanceStatus.otherLesson;
          final List<Map<String, Object?>> otherGroupsToday = await db.rawQuery(
            '''
            SELECT g.name, gs.time 
            FROM group_schedules gs
            JOIN groups g ON gs.group_id = g.id
            WHERE gs.day_of_week IN (?, ?, ?)
          ''',
            [currentDayName, currentDayNameAr, currentDayNameArAlt],
          );

          if (otherGroupsToday.isNotEmpty) {
            final String groupName = _findClosestGroup(otherGroupsToday, now);
            notesToInsert = LocaleKeys.attended_another_group.tr(
              args: [groupName],
            );
          } else {
            // No groups scheduled today at all — generic other lesson
            finalStatus = AttendanceStatus.otherLesson;
            notesToInsert =
                ''; // Empty notes will fall back to "LocaleKeys.other_lesson" in UI
          }
        }
      } else {
        // No group assigned to student — check if any group meets today
        final List<Map<String, Object?>> anyGroupsToday = await db.rawQuery(
          '''
          SELECT g.name, gs.time
          FROM group_schedules gs
          JOIN groups g ON gs.group_id = g.id
          WHERE gs.day_of_week IN (?, ?, ?)
        ''',
          [currentDayName, currentDayNameAr, currentDayNameArAlt],
        );

        if (anyGroupsToday.isNotEmpty) {
          final String groupName = _findClosestGroup(anyGroupsToday, now);
          notesToInsert = LocaleKeys.attended_another_group.tr(
            args: [groupName],
          );
          finalStatus = AttendanceStatus.otherLesson;
        }
      }

      // Check if already recorded today
      final List<Map<String, Object?>> existing = await db.query(
        'attendance',
        where: 'student_id = ? AND date = ?',
        whereArgs: <Object?>[studentId, today],
      );

      if (existing.isNotEmpty) {
        emit(
          state.copyWith(
            error: 'Attendance already recorded for $studentName today',
            scanSuccess: false,
          ),
        );
        return;
      }

      await db.insert('attendance', <String, Object?>{
        'student_id': studentId,
        'date': today,
        'status': finalStatus.name,
        'notes': notesToInsert,
      });

      // Reload attendance history so UI gets the latest
      final List<Map<String, Object?>> latestRecords = await db.rawQuery('''
        SELECT a.*, s.name as student_name 
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        ORDER BY a.id DESC LIMIT 5
      ''');

      emit(
        state.copyWith(
          records: latestRecords,
          scanSuccess: true,
          lastScannedStudent: studentName,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), scanSuccess: false));
    }
  }

  /// Add attendance manually for a specific student and date.
  Future<void> addAttendance({
    required int studentId,
    required DateTime date,
    required AttendanceStatus status,
    String notes = '',
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert('attendance', <String, Object?>{
        'student_id': studentId,
        'date': date.toIso8601String().split('T').first,
        'status': status.name,
        'notes': notes,
      });
      await loadAttendance(studentId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Update an existing attendance record.
  Future<void> updateAttendance(
    int id,
    AttendanceStatus status, {
    String? notes,
  }) async {
    try {
      final Database db = await _databaseService.database;
      final Map<String, Object?> updates = <String, Object?>{
        'status': status.name,
      };
      if (notes != null) updates['notes'] = notes;

      await db.update(
        'attendance',
        updates,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAttendance(int id, {int? studentId}) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete('attendance', where: 'id = ?', whereArgs: <Object?>[id]);
      if (studentId != null) {
        await loadAttendance(studentId);
      } else {
        await loadAllAttendance();
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void resetScanState() {
    emit(
      state.copyWith(scanSuccess: false, lastScannedStudent: null, error: null),
    );
  }

  String _findClosestGroup(
    List<Map<String, Object?>> groupsWithTimes,
    DateTime now,
  ) {
    String? closestGroupName;
    int minDifference = 999999999;

    for (final group in groupsWithTimes) {
      final String? timeStr = group['time'] as String?;
      final String name = group['name'] as String;

      if (timeStr == null || timeStr.isEmpty) {
        closestGroupName ??= name;
        continue;
      }

      final DateTime? parsedDate = _parseTimeToDateTime(timeStr, now);
      if (parsedDate != null) {
        final int diff =
            (parsedDate.millisecondsSinceEpoch - now.millisecondsSinceEpoch)
                .abs();
        if (diff < minDifference) {
          minDifference = diff;
          closestGroupName = name;
        }
      } else {
        closestGroupName ??= name;
      }
    }
    return closestGroupName ??
        (groupsWithTimes.isNotEmpty
            ? groupsWithTimes.first['name'] as String
            : '');
  }

  DateTime? _parseTimeToDateTime(String timeString, DateTime now) {
    if (timeString.isEmpty) return null;
    try {
      final RegExp re = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = re.firstMatch(timeString);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String? period = match.group(3);

        if (period != null) {
          if (period.toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    } catch (_) {}
    return null;
  }

  String _getArabicDayName(String englishDayName) {
    switch (englishDayName) {
      case 'Saturday':
        return 'السبت';
      case 'Sunday':
        return 'الأحد';
      case 'Monday':
        return 'الإثنين';
      case 'Tuesday':
        return 'الثلاثاء';
      case 'Wednesday':
        return 'الأربعاء';
      case 'Thursday':
        return 'الخميس';
      case 'Friday':
        return 'الجمعة';
      default:
        return englishDayName;
    }
  }
}

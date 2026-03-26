import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';

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
      final List<Map<String, Object?>> results = await db.query(
        'attendance',
        where: 'student_id = ?',
        whereArgs: <Object?>[studentId],
        orderBy: 'date DESC',
      );
      emit(state.copyWith(records: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
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
        emit(state.copyWith(
          error: 'Student not found with serial: $serialNumber',
          scanSuccess: false,
        ));
        return;
      }

      final Map<String, Object?> student = students.first;
      final int studentId = student['id'] as int;
      final String studentName = student['name'] as String;
      final String today = DateTime.now().toIso8601String().split('T').first;

      // Check if already recorded today
      final List<Map<String, Object?>> existing = await db.query(
        'attendance',
        where: 'student_id = ? AND date = ?',
        whereArgs: <Object?>[studentId, today],
      );

      if (existing.isNotEmpty) {
        emit(state.copyWith(
          error: 'Attendance already recorded for $studentName today',
          scanSuccess: false,
        ));
        return;
      }

      await db.insert('attendance', <String, Object?>{
        'student_id': studentId,
        'date': today,
        'status': status.name,
        'notes': notes,
      });

      emit(state.copyWith(
        scanSuccess: true,
        lastScannedStudent: studentName,
        error: null,
      ));
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
  Future<void> updateAttendance(int id, AttendanceStatus status, {String? notes}) async {
    try {
      final Database db = await _databaseService.database;
      final Map<String, Object?> updates = <String, Object?>{'status': status.name};
      if (notes != null) updates['notes'] = notes;

      await db.update('attendance', updates, where: 'id = ?', whereArgs: <Object?>[id]);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteAttendance(int id, int studentId) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete('attendance', where: 'id = ?', whereArgs: <Object?>[id]);
      await loadAttendance(studentId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void resetScanState() {
    emit(state.copyWith(scanSuccess: false, lastScannedStudent: null, error: null));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/services/database_service.dart';

part 'dashboard_cubit.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const factory DashboardState({
    @Default(0) int totalStudents,
    @Default(0) int totalGroups,
    @Default(0.0) double attendanceRate,
    @Default(0.0) double paymentCollectionRate,
    @Default(0) int upcomingExams,
    @Default([]) List<Map<String, dynamic>> recentAttendance,
    @Default([]) List<Map<String, dynamic>> recentPayments,
    @Default(false) bool isLoading,
    String? error,
  }) = _DashboardState;
}

class DashboardCubit extends Cubit<DashboardState> {
  final DatabaseService _databaseService;

  DashboardCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const DashboardState());

  Future<void> loadDashboard() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;

      // Total students
      final studentCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM students')) ??
          0;

      // Total groups
      final groupCount = Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM groups')) ??
          0;

      // Attendance rate (last 30 days)
      final today = DateTime.now();
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));
      final attendanceStats = await db.rawQuery('''
        SELECT 
          COUNT(*) as total,
          SUM(CASE WHEN status = 'attended' THEN 1 ELSE 0 END) as attended
        FROM attendance
        WHERE date >= ?
      ''', [thirtyDaysAgo.toIso8601String().split('T').first]);

      double attendanceRate = 0;
      if (attendanceStats.isNotEmpty) {
        final total = (attendanceStats.first['total'] as num?)?.toDouble() ?? 0;
        final attended = (attendanceStats.first['attended'] as num?)?.toDouble() ?? 0;
        if (total > 0) attendanceRate = (attended / total) * 100;
      }

      // Payment collection rate (current month)
      final paymentStats = await db.rawQuery('''
        SELECT 
          SUM(total_amount) as total_due,
          SUM(paid_amount) as total_paid
        FROM payments
        WHERE month = ? AND year = ?
      ''', [today.month, today.year]);

      double paymentRate = 0;
      if (paymentStats.isNotEmpty) {
        final totalDue = (paymentStats.first['total_due'] as num?)?.toDouble() ?? 0;
        final totalPaid = (paymentStats.first['total_paid'] as num?)?.toDouble() ?? 0;
        if (totalDue > 0) paymentRate = (totalPaid / totalDue) * 100;
      }

      // Upcoming exams
      final upcomingExamCount = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(*) FROM exams WHERE date >= ?',
            [today.toIso8601String().split('T').first],
          )) ??
          0;

      // Recent attendance (last 5)
      final recentAttendance = await db.rawQuery('''
        SELECT a.*, s.name as student_name
        FROM attendance a
        JOIN students s ON a.student_id = s.id
        ORDER BY a.date DESC, a.id DESC
        LIMIT 5
      ''');

      // Recent payments (last 5)
      final recentPayments = await db.rawQuery('''
        SELECT p.*, s.name as student_name
        FROM payments p
        JOIN students s ON p.student_id = s.id
        ORDER BY p.paid_date DESC
        LIMIT 5
      ''');

      emit(state.copyWith(
        totalStudents: studentCount,
        totalGroups: groupCount,
        attendanceRate: attendanceRate,
        paymentCollectionRate: paymentRate,
        upcomingExams: upcomingExamCount,
        recentAttendance: recentAttendance,
        recentPayments: recentPayments,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/services/database_service.dart';

part 'payment_cubit.freezed.dart';

@freezed
abstract class PaymentState with _$PaymentState {
  const factory PaymentState({
    @Default([]) List<Map<String, dynamic>> payments,
    @Default(false) bool isLoading,
    @Default(0.0) double totalSurplus,
    String? error,
  }) = _PaymentState;
}

class PaymentCubit extends Cubit<PaymentState> {
  final DatabaseService _databaseService;

  PaymentCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const PaymentState());

  /// Load payments for a specific student.
  Future<void> loadPayments(int studentId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.query(
        'payments',
        where: 'student_id = ?',
        whereArgs: <Object?>[studentId],
        orderBy: 'year DESC, month DESC',
      );

      // Calculate total surplus (carry-forward) for this student
      final double surplus = _calculateTotalSurplus(results);

      emit(state.copyWith(
        payments: results,
        totalSurplus: surplus,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Add or update a monthly payment. If it exists, adds to paid amount and updates total. If new, creates it with surplus.
  Future<void> addOrUpdateMonthPayment({
    required int studentId,
    required int month,
    required int year,
    required double totalAmount,
    required double paidAmount,
  }) async {
    try {
      final Database db = await _databaseService.database;

      // Check if a payment for this month/year already exists
      final List<Map<String, Object?>> existing = await db.query(
        'payments',
        where: 'student_id = ? AND month = ? AND year = ?',
        whereArgs: <Object?>[studentId, month, year],
      );

      if (existing.isNotEmpty) {
        // Update existing record
        final Map<String, Object?> record = existing.first;
        final int id = record['id'] as int;
        final double currentPaid = (record['paid_amount'] as num).toDouble();
        
        await db.update(
          'payments',
          <String, Object?>{
            'total_amount': totalAmount,
            'paid_amount': currentPaid + paidAmount,
            'paid_date': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      } else {
        // Check for existing surplus from previous months
        final double previousSurplus = await _getAccumulatedSurplus(studentId, month, year);
        final double effectivePaid = paidAmount + previousSurplus;

        await db.insert('payments', <String, Object?>{
          'student_id': studentId,
          'month': month,
          'year': year,
          'total_amount': totalAmount,
          'paid_amount': effectivePaid,
          'paid_date': DateTime.now().toIso8601String(),
        });
      }

      await loadPayments(studentId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updatePayment(int id, Map<String, dynamic> data) async {
    try {
      final Database db = await _databaseService.database;
      await db.update('payments', data, where: 'id = ?', whereArgs: <Object?>[id]);

      // Reload for the student
      final Object? studentId = data['student_id'];
      if (studentId != null) await loadPayments(studentId as int);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deletePayment(int id, int studentId) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete('payments', where: 'id = ?', whereArgs: <Object?>[id]);
      await loadPayments(studentId);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Calculate accumulated surplus from all previous months.
  Future<double> _getAccumulatedSurplus(int studentId, int currentMonth, int currentYear) async {
    final Database db = await _databaseService.database;
    final List<Map<String, Object?>> results = await db.query(
      'payments',
      where: 'student_id = ? AND ((year < ?) OR (year = ? AND month < ?))',
      whereArgs: <Object?>[studentId, currentYear, currentYear, currentMonth],
      orderBy: 'year ASC, month ASC',
    );

    double surplus = 0;
    for (final Map<String, Object?> row in results) {
      final double total = (row['total_amount'] as num).toDouble();
      final double paid = (row['paid_amount'] as num).toDouble();
      if (paid > total) {
        surplus += (paid - total);
      }
    }
    return surplus;
  }

  double _calculateTotalSurplus(List<Map<String, Object?>> payments) {
    double surplus = 0;
    for (final Map<String, Object?> p in payments) {
      final double total = (p['total_amount'] as num).toDouble();
      final double paid = (p['paid_amount'] as num).toDouble();
      if (paid > total) {
        surplus += (paid - total);
      }
    }
    return surplus;
  }
}

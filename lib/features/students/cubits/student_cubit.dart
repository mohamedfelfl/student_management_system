import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../app/services/database_service.dart';

part 'student_cubit.freezed.dart';

@freezed
abstract class StudentState with _$StudentState {
  const factory StudentState({
    @Default([]) List<Map<String, dynamic>> students,
    @Default(false) bool isLoading,
    @Default('') String searchQuery,
    @Default(0) int totalCount,
    @Default({}) Set<int> selectedIds,
    int? selectedGroupId,
    String? error,
  }) = _StudentState;
}

class StudentCubit extends Cubit<StudentState> {
  final DatabaseService _databaseService;

  StudentCubit({required DatabaseService databaseService})
    : _databaseService = databaseService,
      super(const StudentState());

  Future<void> loadStudents() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;

      // Always fetch total count (unfiltered)
      final List<Map<String, Object?>> countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM students',
      );
      final int total = (countResult.first['cnt'] as int?) ?? 0;

      // Fetch filtered results
      final String query =
          '''
        SELECT s.*, g.name as group_name 
        FROM students s 
        LEFT JOIN groups g ON s.group_id = g.id
        ${_buildWhereClause()}
        ORDER BY s.name ASC
      ''';
      final List<Map<String, Object?>> results = await db.rawQuery(
        query,
        _buildWhereArgs(),
      );

      // Prune selectedIds to only include IDs still in the result set
      final resultIds = results.map((s) => s['id'] as int).toSet();
      final pruned = state.selectedIds.intersection(resultIds);

      emit(
        state.copyWith(
          students: results,
          totalCount: total,
          selectedIds: pruned,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query, selectedIds: const {}));
    loadStudents();
  }

  void filterByGroup(int? groupId) {
    emit(state.copyWith(selectedGroupId: groupId));
    loadStudents();
  }

  // ── Selection helpers ──

  void toggleSelection(int id) {
    final updated = Set<int>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    emit(state.copyWith(selectedIds: updated));
  }

  void toggleAll() {
    if (state.selectedIds.length == state.students.length) {
      // Deselect all
      emit(state.copyWith(selectedIds: const {}));
    } else {
      // Select all visible
      final allIds = state.students.map((s) => s['id'] as int).toSet();
      emit(state.copyWith(selectedIds: allIds));
    }
  }

  void clearSelection() {
    emit(state.copyWith(selectedIds: const {}));
  }

  // ── CRUD ──

  Future<void> createStudent(Map<String, dynamic> data) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert('students', data);
      await loadStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      final Database db = await _databaseService.database;
      await db.update(
        'students',
        data,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      await loadStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete('students', where: 'id = ?', whereArgs: <Object?>[id]);
      await loadStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteMultipleStudents(Set<int> ids) async {
    if (ids.isEmpty) return;
    try {
      final Database db = await _databaseService.database;
      final placeholders = List.filled(ids.length, '?').join(',');
      await db.rawDelete(
        'DELETE FROM students WHERE id IN ($placeholders)',
        ids.toList(),
      );
      emit(state.copyWith(selectedIds: const {}));
      await loadStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<Map<String, dynamic>?> getStudentById(int id) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery(
        '''
        SELECT s.*, g.name as group_name
        FROM students s
        LEFT JOIN groups g ON s.group_id = g.id
        WHERE s.id = ?
      ''',
        <Object?>[id],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getStudentBySerial(String serial) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery(
        '''
        SELECT s.*, g.name as group_name
        FROM students s
        LEFT JOIN groups g ON s.group_id = g.id
        WHERE s.serial_number = ?
      ''',
        <Object?>[serial],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  String _buildWhereClause() {
    final List<String> conditions = <String>[];
    if (state.searchQuery.isNotEmpty) {
      conditions.add(
        '(s.name LIKE ? OR s.serial_number LIKE ? OR s.phone1 LIKE ?)',
      );
    }
    if (state.selectedGroupId != null) {
      conditions.add('s.group_id = ?');
    }
    return conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
  }

  List<Object?> _buildWhereArgs() {
    final List<Object?> args = <Object?>[];
    if (state.searchQuery.isNotEmpty) {
      final String q = '%${state.searchQuery}%';
      args.addAll(<Object?>[q, q, q]);
    }
    if (state.selectedGroupId != null) {
      args.add(state.selectedGroupId);
    }
    return args;
  }
}

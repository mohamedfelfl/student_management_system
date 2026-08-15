import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../app/services/database_service.dart';
import '../../../app/constants/db_queries.dart';

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
        DBQueries.countStudents,
      );
      final int total = (countResult.first['cnt'] as int?) ?? 0;

      // Fetch filtered results
      final String query =
          '''
        ${DBQueries.getStudentsBase}
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

  Future<String> createStudent(Map<String, dynamic> data) async {
    try {
      final Database db = await _databaseService.database;
      final name = data['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        final existing = await db.query(
          DBQueries.tableStudents,
          where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
          whereArgs: [name],
        );
        if (existing.isNotEmpty) {
          throw Exception('student_name_exists');
        }
      }

      final grade = (data['grade']?.toString() ?? 'prep_1').trim().toLowerCase();
      String serial = data['serial_number']?.toString().trim() ?? '';

      // Perform atomic serial check, allocation & insertion inside a database transaction
      final finalSerial = await db.transaction<String>((txn) async {
        bool needsRecalculation = serial.isEmpty;
        if (!needsRecalculation) {
          final existing = await txn.rawQuery(
            'SELECT id FROM ${DBQueries.tableStudents} WHERE serial_number = ?',
            [serial],
          );
          if (existing.isNotEmpty) {
            needsRecalculation = true;
          }
        }

        if (needsRecalculation) {
          serial = await _calculateNextSerial(txn, grade);
        }

        final Map<String, dynamic> insertData = Map<String, dynamic>.from(data);
        insertData['serial_number'] = serial;
        insertData['grade'] = grade;

        await txn.insert(DBQueries.tableStudents, insertData);

        // Update tracking counter in app_settings table
        final parsedSerial = int.tryParse(serial);
        if (parsedSerial != null) {
          await txn.insert(
            DBQueries.tableAppSettings,
            {
              'key': 'serial_counter_$grade',
              'value': parsedSerial.toString(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        return serial;
      });

      await loadStudents();
      return finalSerial;
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateStudent(int id, Map<String, dynamic> data) async {
    try {
      final Database db = await _databaseService.database;
      final name = data['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        final existing = await db.query(
          DBQueries.tableStudents,
          where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND id != ?',
          whereArgs: [name, id],
        );
        if (existing.isNotEmpty) {
          throw Exception('student_name_exists');
        }
      }

      await db.update(
        DBQueries.tableStudents,
        data,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
      await loadStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete(
        DBQueries.tableStudents,
        where: 'id = ?',
        whereArgs: <Object?>[id],
      );
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
        '${DBQueries.deleteMultipleStudentsBase} ($placeholders)',
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
        DBQueries.getStudentById,
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
        DBQueries.getStudentBySerial,
        <Object?>[serial],
      );
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      return null;
    }
  }

  static const Map<String, int> kGradeBaseSerials = {
    'prep_1': 10777,
    'prep_2': 20777,
    'prep_3': 30777,
    'sec_1': 40777,
    'sec_2': 50777,
    'sec_3': 60777,
  };

  static const Map<String, ({int base, int min, int max})> kGradeSerialRanges = {
    'prep_1': (base: 10777, min: 10000, max: 19999),
    'prep_2': (base: 20777, min: 20000, max: 29999),
    'prep_3': (base: 30777, min: 30000, max: 39999),
    'sec_1': (base: 40777, min: 40000, max: 49999),
    'sec_2': (base: 50777, min: 50000, max: 59999),
    'sec_3': (base: 60777, min: 60000, max: 69999),
  };

  Future<String> _calculateNextSerial(dynamic executor, String grade) async {
    final String cleanGrade = grade.trim().toLowerCase();
    final config = kGradeSerialRanges[cleanGrade] ??
        (base: kGradeBaseSerials[cleanGrade] ?? 10777, min: 10000, max: 19999);
    final int base = config.base;

    int maxSerial = base - 1;

    // 1. Read tracked counter from app_settings
    try {
      final List<Map<String, Object?>> tracked = await executor.rawQuery(
        'SELECT value FROM ${DBQueries.tableAppSettings} WHERE key = ?',
        ['serial_counter_$cleanGrade'],
      );
      if (tracked.isNotEmpty) {
        final trackedVal = int.tryParse(tracked.first['value']?.toString().trim() ?? '');
        if (trackedVal != null && trackedVal > maxSerial) {
          maxSerial = trackedVal;
        }
      }
    } catch (_) {}

    // 2. Read existing serials from students table
    final List<Map<String, Object?>> rows = await executor.rawQuery(
      'SELECT serial_number, grade FROM ${DBQueries.tableStudents}',
    );

    final Set<String> existingSerials = <String>{};

    for (final row in rows) {
      final serialRaw = row['serial_number']?.toString().trim();
      if (serialRaw == null || serialRaw.isEmpty) continue;
      existingSerials.add(serialRaw);

      final rowGrade = row['grade']?.toString().trim().toLowerCase();
      final parsed = int.tryParse(serialRaw);

      if (parsed != null) {
        final isSameGrade = (rowGrade == cleanGrade);
        final isInRange = (parsed >= config.min && parsed <= config.max);

        if (isSameGrade || isInRange) {
          if (parsed > maxSerial) {
            maxSerial = parsed;
          }
        }
      }
    }

    int candidate = (maxSerial >= base) ? (maxSerial + 1) : base;

    while (existingSerials.contains(candidate.toString())) {
      candidate++;
    }

    return candidate.toString();
  }

  Future<String> getNextSerialNumber(String grade) async {
    try {
      final Database db = await _databaseService.database;
      return await _calculateNextSerial(db, grade);
    } catch (e) {
      final cleanGrade = grade.trim().toLowerCase();
      final base = kGradeBaseSerials[cleanGrade] ?? 10777;
      return base.toString();
    }
  }

  String _buildWhereClause() {
    final List<String> conditions = <String>[];
    if (state.searchQuery.isNotEmpty) {
      conditions.add(DBQueries.studentSearchCondition);
    }
    if (state.selectedGroupId != null) {
      conditions.add(DBQueries.studentGroupCondition);
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

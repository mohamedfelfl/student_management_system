import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../app/services/database_service.dart';

part 'group_cubit.freezed.dart';

@freezed
abstract class GroupState with _$GroupState {
  const factory GroupState({
    @Default([]) List<Map<String, dynamic>> groups,
    @Default([]) List<Map<String, dynamic>> groupStudents,
    @Default([]) List<Map<String, dynamic>> availableStudents,
    @Default(false) bool isLoading,
    String? error,
  }) = _GroupState;
}

class GroupCubit extends Cubit<GroupState> {
  final DatabaseService _databaseService;

  GroupCubit({required DatabaseService databaseService})
    : _databaseService = databaseService,
      super(const GroupState());

  Future<void> loadGroups() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;

      // Load groups with student count
      final groupResults = await db.rawQuery('''
        SELECT g.*, COUNT(s.id) as student_count
        FROM groups g
        LEFT JOIN students s ON s.group_id = g.id
        GROUP BY g.id
        ORDER BY g.name ASC
      ''');

      final List<Map<String, dynamic>> groupsWithSchedules = [];

      for (final g in groupResults) {
        final mutableGroup = Map<String, dynamic>.from(g);
        final groupId = g['id'];

        // Load schedules for this group
        final scheduleResults = await db.query(
          'group_schedules',
          where: 'group_id = ?',
          whereArgs: [groupId],
        );

        mutableGroup['schedules'] = scheduleResults;
        groupsWithSchedules.add(mutableGroup);
      }

      emit(state.copyWith(groups: groupsWithSchedules, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> createGroup(Map<String, dynamic> data) async {
    try {
      final List<Map<String, dynamic>> schedules =
          List<Map<String, dynamic>>.from(data.remove('schedules') ?? []);

      final db = await _databaseService.database;
      await db.transaction((txn) async {
        final groupId = await txn.insert('groups', data);

        for (final schedule in schedules) {
          await txn.insert('group_schedules', {
            ...schedule,
            'group_id': groupId,
          });
        }
      });

      await loadGroups();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateGroup(int id, Map<String, dynamic> data) async {
    try {
      final List<Map<String, dynamic>> schedules =
          List<Map<String, dynamic>>.from(data.remove('schedules') ?? []);

      final db = await _databaseService.database;
      await db.transaction((txn) async {
        await txn.update('groups', data, where: 'id = ?', whereArgs: [id]);

        // Refresh schedules: delete and re-insert
        await txn.delete(
          'group_schedules',
          where: 'group_id = ?',
          whereArgs: [id],
        );

        for (final schedule in schedules) {
          await txn.insert('group_schedules', {...schedule, 'group_id': id});
        }
      });

      await loadGroups();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteGroup(int id) async {
    try {
      final db = await _databaseService.database;
      await db.delete('groups', where: 'id = ?', whereArgs: [id]);
      await loadGroups();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  // ── Student linking ──

  /// Load students currently assigned to this group.
  Future<void> loadGroupStudents(int groupId) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'students',
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'name ASC',
      );
      emit(state.copyWith(groupStudents: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Load students not currently in any group (available for linking).
  Future<void> loadAvailableStudents({String search = ''}) async {
    try {
      final db = await _databaseService.database;
      String query = 'SELECT * FROM students WHERE group_id IS NULL';
      final List<Object?> args = <Object?>[];
      if (search.isNotEmpty) {
        query += ' AND (name LIKE ? OR serial_number LIKE ?)';
        args.add('%$search%');
        args.add('%$search%');
      }
      query += ' ORDER BY name ASC';
      final results = await db.rawQuery(query, args);
      emit(state.copyWith(availableStudents: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Link a student to this group.
  Future<void> linkStudentToGroup(int studentId, int groupId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'students',
        {'group_id': groupId},
        where: 'id = ?',
        whereArgs: [studentId],
      );
      await loadGroupStudents(groupId);
      await loadAvailableStudents();
      await loadGroups();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Unlink a student from their group.
  Future<void> unlinkStudentFromGroup(int studentId, int groupId) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        'students',
        {'group_id': null},
        where: 'id = ?',
        whereArgs: [studentId],
      );
      await loadGroupStudents(groupId);
      await loadAvailableStudents();
      await loadGroups();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}

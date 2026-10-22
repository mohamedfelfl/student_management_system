import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../app/constants/db_queries.dart';
import '../../../app/services/database_service.dart';
import '../../../app/di/injection.dart';
import '../../../app/services/data_sync_service.dart';

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
  final DataSyncService? _dataSyncService;
  StreamSubscription<SyncEntity>? _syncSub;

  GroupCubit({
    required DatabaseService databaseService,
    DataSyncService? dataSyncService,
  })  : _databaseService = databaseService,
        _dataSyncService = dataSyncService ?? (getIt.isRegistered<DataSyncService>() ? getIt<DataSyncService>() : null),
        super(const GroupState()) {
    _syncSub = _dataSyncService?.syncStream.listen((entity) {
      if (entity == SyncEntity.students) {
        loadGroups(silent: true);
      }
    });
  }

  Future<void> loadGroups({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, error: null));
    }
    try {
      final db = await _databaseService.database;

      // Load groups with student count
      final List<Map<String, Object?>> groupResults =
          await db.rawQuery(DBQueries.loadGroupsWithStudentCount);

      // Batch load all group schedules in a single query to eliminate N+1 overhead
      final allSchedules = await db.query(DBQueries.tableGroupSchedules);
      final schedulesByGroupId = <dynamic, List<Map<String, dynamic>>>{};
      for (final s in allSchedules) {
        final gid = s['group_id'];
        schedulesByGroupId.putIfAbsent(gid, () => []).add(Map<String, dynamic>.from(s));
      }

      final List<Map<String, dynamic>> groupsWithSchedules = [];

      for (final g in groupResults) {
        final mutableGroup = Map<String, dynamic>.from(g);
        final groupId = g['id'];
        mutableGroup['schedules'] = schedulesByGroupId[groupId] ?? const <Map<String, dynamic>>[];
        groupsWithSchedules.add(mutableGroup);
      }

      emit(state.copyWith(groups: groupsWithSchedules, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> createGroup(Map<String, dynamic> data) async {
    try {
      final String name = data['name']?.toString().trim() ?? '';
      final db = await _databaseService.database;

      final existing = await db.query(
        DBQueries.tableGroups,
        where: 'LOWER(TRIM(name)) = LOWER(TRIM(?))',
        whereArgs: [name],
      );
      if (existing.isNotEmpty) {
        throw Exception('group_name_exists');
      }

      final List<Map<String, dynamic>> schedules =
          List<Map<String, dynamic>>.from(data.remove('schedules') ?? []);
      final List<int> studentIds = List<int>.from(
        data.remove('studentIds') ?? [],
      );

      await db.transaction((txn) async {
        final groupId = await txn.insert(DBQueries.tableGroups, data);

        for (final schedule in schedules) {
          await txn.insert(DBQueries.tableGroupSchedules, {
            ...schedule,
            'group_id': groupId,
          });
        }

        // Link students to the new group
        for (final studentId in studentIds) {
          await txn.update(
            DBQueries.tableStudents,
            {'group_id': groupId},
            where: 'id = ?',
            whereArgs: [studentId],
          );
        }
      });

      await loadGroups(silent: true);
      _dataSyncService?.notifyGroupsChanged();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  Future<void> updateGroup(int id, Map<String, dynamic> data) async {
    try {
      final String name = data['name']?.toString().trim() ?? '';
      final db = await _databaseService.database;

      final existing = await db.query(
        DBQueries.tableGroups,
        where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND id != ?',
        whereArgs: [name, id],
      );
      if (existing.isNotEmpty) {
        throw Exception('group_name_exists');
      }

      final List<Map<String, dynamic>> schedules =
          List<Map<String, dynamic>>.from(data.remove('schedules') ?? []);

      await db.transaction((txn) async {
        await txn.update(DBQueries.tableGroups, data, where: 'id = ?', whereArgs: [id]);

        // Refresh schedules: delete and re-insert
        await txn.rawDelete(
          DBQueries.deleteGroupSchedulesByGroupId,
          [id],
        );

        for (final schedule in schedules) {
          await txn.insert(DBQueries.tableGroupSchedules, {...schedule, 'group_id': id});
        }
      });

      await loadGroups(silent: true);
      _dataSyncService?.notifyGroupsChanged();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
      rethrow;
    }
  }

  /// Counts what [deleteGroup] would remove, so the user can confirm it.
  Future<GroupDeletionImpact> getDeletionImpact(int groupId) async {
    final db = await _databaseService.database;
    Future<int> count(String sql) async =>
        (await db.rawQuery(sql, [groupId])).first['cnt'] as int? ?? 0;

    return GroupDeletionImpact(
      lessons: await count(
        'SELECT COUNT(*) AS cnt FROM lessons WHERE group_id = ?',
      ),
      attendanceRecords: await count(
        'SELECT COUNT(*) AS cnt FROM attendance a '
        'JOIN lessons l ON a.lesson_id = l.id WHERE l.group_id = ?',
      ),
      students: await count(
        'SELECT COUNT(*) AS cnt FROM students WHERE group_id = ?',
      ),
    );
  }

  Future<void> deleteGroup(int id) async {
    try {
      final db = await _databaseService.database;
      await db.delete(DBQueries.tableGroups, where: 'id = ?', whereArgs: [id]);
      await loadGroups(silent: true);
      _dataSyncService?.notifyGroupsChanged();
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
        DBQueries.tableStudents,
        where: 'group_id = ?',
        whereArgs: [groupId],
        orderBy: 'name ASC',
      );
      emit(state.copyWith(groupStudents: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Load students not currently in any group (available for linking), optionally filtered by grade/stage.
  Future<void> loadAvailableStudents({String search = '', String? grade}) async {
    try {
      final db = await _databaseService.database;
      String query = DBQueries.loadAvailableStudentsBase;
      final List<Object?> args = <Object?>[];
      if (grade != null && grade.isNotEmpty) {
        query += ' AND grade = ?';
        args.add(grade);
      }
      if (search.isNotEmpty) {
        query += DBQueries.availableStudentsSearchCondition;
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
  Future<void> linkStudentToGroup(int studentId, int groupId, {String? grade}) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        DBQueries.tableStudents,
        {'group_id': groupId},
        where: 'id = ?',
        whereArgs: [studentId],
      );
      await loadGroupStudents(groupId);
      await loadAvailableStudents(grade: grade);
      await loadGroups(silent: true);
      _dataSyncService?.notifyGroupsChanged();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Unlink a student from their group.
  Future<void> unlinkStudentFromGroup(int studentId, int groupId, {String? grade}) async {
    try {
      final db = await _databaseService.database;
      await db.update(
        DBQueries.tableStudents,
        {'group_id': null},
        where: 'id = ?',
        whereArgs: [studentId],
      );
      await loadGroupStudents(groupId);
      await loadAvailableStudents(grade: grade);
      await loadGroups(silent: true);
      _dataSyncService?.notifyGroupsChanged();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _syncSub?.cancel();
    return super.close();
  }
}

/// What deleting a group removes or changes, shown before the user confirms.
class GroupDeletionImpact {
  /// Lessons of the group (deleted by cascade).
  final int lessons;

  /// Attendance rows of those lessons (deleted by cascade).
  final int attendanceRecords;

  /// Students currently in the group (left without a group).
  final int students;

  const GroupDeletionImpact({
    required this.lessons,
    required this.attendanceRecords,
    required this.students,
  });
}

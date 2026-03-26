import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../../../app/services/database_service.dart';

import '../models/student_exam_result.dart';

part 'exam_cubit.freezed.dart';

@freezed
abstract class ExamState with _$ExamState {
  const factory ExamState({
    @Default([]) List<Map<String, dynamic>> exams,
    @Default([]) List<Map<String, dynamic>> marks,
    @Default([]) List<Map<String, dynamic>> groups,
    @Default([]) List<Map<String, dynamic>> groupStudents,
    @Default([]) List<StudentExamResult> topStudents,
    @Default(0.0) double averageScore,
    @Default(false) bool isLoading,
    String? error,
  }) = _ExamState;
}

class ExamCubit extends Cubit<ExamState> {
  final DatabaseService _databaseService;

  ExamCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const ExamState());

  Future<void> loadInitialData({DateTime? startDate, DateTime? endDate}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      await loadExams();
      await loadGroups();
      await calculateAverageScore();
      await getTopStudents(startDate: startDate, endDate: endDate);
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> loadExams() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.query('exams', orderBy: 'date DESC');
      emit(state.copyWith(exams: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> loadGroups() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.query('groups', orderBy: 'name ASC');
      emit(state.copyWith(groups: results));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> createExam(Map<String, dynamic> data, {List<int>? groupIds}) async {
    try {
      final Database db = await _databaseService.database;
      await db.transaction((txn) async {
        final id = await txn.insert('exams', data);
        if (groupIds != null && groupIds.isNotEmpty) {
          for (final groupId in groupIds) {
            await txn.insert('exam_groups', {'exam_id': id, 'group_id': groupId});
          }
        }
      });
      await loadInitialData();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> updateExam(int id, Map<String, dynamic> data, {List<int>? groupIds}) async {
    try {
      final Database db = await _databaseService.database;
      await db.transaction((txn) async {
        await txn.update('exams', data, where: 'id = ?', whereArgs: <Object?>[id]);
        if (groupIds != null) {
          await txn.delete('exam_groups', where: 'exam_id = ?', whereArgs: [id]);
          for (final groupId in groupIds) {
            await txn.insert('exam_groups', {'exam_id': id, 'group_id': groupId});
          }
        }
      });
      await loadInitialData();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteExam(int id) async {
    try {
      final Database db = await _databaseService.database;
      await db.delete('exams', where: 'id = ?', whereArgs: <Object?>[id]);
      await loadInitialData();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> calculateAverageScore() async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> totalMarksResult = await db.rawQuery('SELECT SUM(score) as total FROM marks');
      final List<Map<String, Object?>> totalExamsResult = await db.rawQuery('SELECT COUNT(*) as count FROM exams');
      
      final double totalScore = (totalMarksResult.first['total'] as num?)?.toDouble() ?? 0.0;
      final int totalExams = (totalExamsResult.first['count'] as int?) ?? 1;
      
      final double average = totalExams > 0 ? totalScore / totalExams : 0.0;
      emit(state.copyWith(averageScore: average));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> getTopStudents({DateTime? startDate, DateTime? endDate, int? examId}) async {
    try {
      final Database db = await _databaseService.database;
      final List<String> conditions = [];
      List<Object?> args = [];

      if (startDate != null && endDate != null) {
        conditions.add('e.date BETWEEN ? AND ?');
        args.addAll([startDate.toIso8601String().split('T').first, endDate.toIso8601String().split('T').first]);
      }
      if (examId != null) {
        conditions.add('e.id = ?');
        args.add(examId);
      }

      final String whereClause = conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      final List<Map<String, Object?>> results = await db.rawQuery('''
        SELECT 
          s.id as studentId, 
          s.name as studentName, 
          s.serial_number as serialNumber, 
          SUM(m.score) as totalMarks, 
          SUM(e.full_mark) as totalFullMarks,
          COUNT(m.id) as examCount
        FROM students s
        JOIN marks m ON s.id = m.student_id
        JOIN exams e ON m.exam_id = e.id
        $whereClause
        GROUP BY s.id
        ORDER BY totalMarks DESC
      ''', args);

      final List<StudentExamResult> topStudents = results.map((r) {
        final double totalMarks = (r['totalMarks'] as num).toDouble();
        final double totalFullMarks = (r['totalFullMarks'] as num).toDouble();
        final double percentage = totalFullMarks > 0 ? (totalMarks / totalFullMarks) * 100 : 0.0;
        
        return StudentExamResult(
          studentId: r['studentId'] as int,
          studentName: r['studentName'] as String,
          serialNumber: r['serialNumber'] as String,
          totalMarks: totalMarks,
          totalFullMarks: totalFullMarks,
          percentage: percentage,
          examCount: r['examCount'] as int,
        );
      }).toList();

      emit(state.copyWith(topStudents: topStudents));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<List<int>> getExamGroups(int examId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.query(
        'exam_groups',
        columns: ['group_id'],
        where: 'exam_id = ?',
        whereArgs: [examId],
      );
      return results.map((r) => r['group_id'] as int).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadGroupStudents(int groupId) async {
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.query(
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

  /// Load marks for a specific exam.
  Future<void> loadMarks(int examId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery('''
        SELECT m.*, s.name as student_name, s.serial_number,
               e.name as exam_name, e.full_mark as exam_full_mark
        FROM marks m
        JOIN students s ON m.student_id = s.id
        JOIN exams e ON m.exam_id = e.id
        WHERE m.exam_id = ?
        ORDER BY m.score DESC
      ''', <Object?>[examId]);
      emit(state.copyWith(marks: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Load all marks for a specific student.
  Future<void> loadStudentMarks(int studentId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final Database db = await _databaseService.database;
      final List<Map<String, Object?>> results = await db.rawQuery('''
        SELECT m.*, e.name as exam_name, e.full_mark as exam_full_mark, e.date as exam_date
        FROM marks m
        JOIN exams e ON m.exam_id = e.id
        WHERE m.student_id = ?
        ORDER BY e.date DESC
      ''', <Object?>[studentId]);
      emit(state.copyWith(marks: results, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  /// Save or update a mark for a student in an exam.
  Future<void> saveMark({
    required int examId,
    required int studentId,
    required double score,
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert(
        'marks',
        <String, Object?>{
          'exam_id': examId,
          'student_id': studentId,
          'score': score,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await calculateAverageScore();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Batch save marks for multiple students in an exam.
  Future<void> saveMarks(int examId, Map<int, double> studentScores) async {
    try {
      final Database db = await _databaseService.database;
      final Batch batch = db.batch();
      for (final MapEntry<int, double> entry in studentScores.entries) {
        batch.insert(
          'marks',
          <String, Object?>{
            'exam_id': examId,
            'student_id': entry.key,
            'score': entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      await loadMarks(examId);
      await calculateAverageScore();
      await getTopStudents();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  /// Get highest marks for an exam within a score range.
  Future<List<Map<String, Object?>>> getHighestMarks({
    int? examId,
    double? minScore,
    double? maxScore,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Database db = await _databaseService.database;
      final List<String> conditions = <String>[];
      final List<Object?> args = <Object?>[];

      if (examId != null) {
        conditions.add('m.exam_id = ?');
        args.add(examId);
      }
      if (minScore != null) {
        conditions.add('m.score >= ?');
        args.add(minScore);
      }
      if (maxScore != null) {
        conditions.add('m.score <= ?');
        args.add(maxScore);
      }
      if (fromDate != null) {
        conditions.add('e.date >= ?');
        args.add(fromDate.toIso8601String().split('T').first);
      }
      if (toDate != null) {
        conditions.add('e.date <= ?');
        args.add(toDate.toIso8601String().split('T').first);
      }

      final String whereClause = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

      return await db.rawQuery('''
        SELECT m.*, s.name as student_name, s.serial_number,
               e.name as exam_name, e.full_mark as exam_full_mark
        FROM marks m
        JOIN students s ON m.student_id = s.id
        JOIN exams e ON m.exam_id = e.id
        $whereClause
        ORDER BY m.score DESC
      ''', args);
    } catch (e) {
      return [];
    }
  }
}

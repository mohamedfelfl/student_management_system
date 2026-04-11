import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../../app/services/database_service.dart';
import '../models/note.dart';
import 'notes_state.dart';

class NotesCubit extends Cubit<NotesState> {
  final DatabaseService _databaseService;

  NotesCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const NotesState()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query('notes', orderBy: 'id DESC');
      
      final notes = maps.map((e) => Note.fromJson(e)).toList();
      emit(state.copyWith(isLoading: false, notes: notes));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> addNote(String name, double price) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;
      await db.insert('notes', {
        'name': name,
        'price': price,
      });
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> updateNote(int id, String name, double price) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;
      await db.update(
        'notes',
        {
          'name': name,
          'price': price,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> deleteNote(int id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;
      await db.delete(
        'notes',
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadNotes();
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void selectNoteForDelivery(int? noteId) {
    emit(state.copyWith(
      selectedNoteId: noteId, 
      currentDeliveries: {},
      pendingDeliveries: {},
    ));
    if (noteId != null) {
      loadDeliveries(noteId);
    }
  }

  Future<void> loadDeliveries(int noteId) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final db = await _databaseService.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'student_notes',
        where: 'note_id = ?',
        whereArgs: [noteId],
      );
      
      final deliveries = <int, bool>{};
      for (final map in maps) {
        deliveries[map['student_id'] as int] = true;
      }
      
      emit(state.copyWith(
        isLoading: false, 
        currentDeliveries: deliveries,
        pendingDeliveries: {}, // Always start with empty selection
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void updateDeliveryStatusLocal(int studentId, bool delivered) {
    final noteId = state.selectedNoteId;
    if (noteId == null) return;
    
    final newPending = Map<int, bool>.from(state.pendingDeliveries);
    if (delivered) {
      newPending[studentId] = true;
    } else {
      newPending.remove(studentId);
    }
    emit(state.copyWith(pendingDeliveries: newPending));
  }

  void updateBatchDeliveryLocal(List<int> studentIds, bool delivered) {
    final noteId = state.selectedNoteId;
    if (noteId == null || studentIds.isEmpty) return;

    final newPending = Map<int, bool>.from(state.pendingDeliveries);
    for (final id in studentIds) {
      if (delivered) {
        newPending[id] = true;
      } else {
        newPending.remove(id);
      }
    }
    emit(state.copyWith(pendingDeliveries: newPending));
  }

  Future<void> saveDeliveries() async {
    final noteId = state.selectedNoteId;
    if (noteId == null) return;

    emit(state.copyWith(isLoading: true, error: null));

    try {
      final db = await _databaseService.database;
      final newCurrent = Map<int, bool>.from(state.currentDeliveries);
      
      await db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        for (final id in state.pendingDeliveries.keys) {
          if (state.currentDeliveries[id] == true) {
            // Toggle: Already delivered -> Remove
            await txn.delete(
              'student_notes',
              where: 'student_id = ? AND note_id = ?',
              whereArgs: [id, noteId],
            );
            newCurrent.remove(id);
          } else {
            // Toggle: Not delivered -> Add
            await txn.insert(
              'student_notes',
              {
                'student_id': id,
                'note_id': noteId,
                'delivered_date': now,
              },
              conflictAlgorithm: ConflictAlgorithm.ignore,
            );
            newCurrent[id] = true;
          }
        }
      });

      emit(state.copyWith(
        isLoading: false,
        currentDeliveries: newCurrent,
        pendingDeliveries: {}, // Reset after save
        lastSaveTimestamp: DateTime.now(),
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
  void clearPendingDeliveries() {
    emit(state.copyWith(pendingDeliveries: {}));
  }
}

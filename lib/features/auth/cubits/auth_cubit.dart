import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../../../app/services/database_service.dart';

part 'auth_cubit.freezed.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.error(String message) = _Error;
}

class AuthCubit extends Cubit<AuthState> {
  final DatabaseService _databaseService;

  AuthCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(const AuthState.initial());

  Future<void> login(String username, String password) async {
    emit(const AuthState.loading());
    try {
      final Database db = await _databaseService.database;
      final String passwordHash = _hashPassword(password);

      final List<Map<String, Object?>> results = await db.query(
        'users',
        where: 'username = ? AND password_hash = ?',
        whereArgs: [username, passwordHash],
      );

      if (results.isNotEmpty) {
        final Map<String, Object?> row = results.first;
        final User user = User(
          id: row['id'] as int,
          username: row['username'] as String,
          passwordHash: row['password_hash'] as String,
          role: row['role'] == 'admin' ? UserRole.admin : UserRole.user,
          permissions: (jsonDecode(row['permissions'] as String) as List)
              .map((p) => UserPermission.values.firstWhere(
                    (e) => e.name == p,
                    orElse: () => UserPermission.manageStudents,
                  ))
              .toList(),
          createdAt: DateTime.tryParse(row['created_at'] as String? ?? ''),
        );
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Invalid username or password'));
      }
    } catch (e) {
      emit(AuthState.error(e.toString()));
    }
  }

  void logout() {
    emit(const AuthState.initial());
  }

  String _hashPassword(String password) {
    final List<int> bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}

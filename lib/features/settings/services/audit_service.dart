import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../app/services/database_service.dart';

/// Records all operations for audit trail purposes.
///
/// Logs every CRUD operation, login attempt, export, backup, and settings change
/// with user, timestamp, and details.
class AuditService {
  final DatabaseService _databaseService;

  AuditService({required DatabaseService databaseService})
      : _databaseService = databaseService;

  /// Log an audit event.
  Future<void> log({
    required int userId,
    required AuditAction action,
    required String entityType,
    int? entityId,
    Map<String, dynamic>? details,
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert('audit_log', {
        'user_id': userId,
        'action': action.name,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details != null ? jsonEncode(details) : null,
      });
    } catch (e) {
      if (kDebugMode) {
        print('AuditService: Error logging audit event: $e');
      }
    }
  }

  /// Log a login attempt.
  Future<void> logLogin({
    required String username,
    required bool success,
  }) async {
    try {
      final Database db = await _databaseService.database;
      await db.insert('login_attempts', {
        'username': username,
        'success': success ? 1 : 0,
      });
    } catch (e) {
      if (kDebugMode) {
        print('AuditService: Error logging login attempt: $e');
      }
    }
  }

  /// Get audit log entries with pagination.
  Future<List<Map<String, dynamic>>> getAuditLog({
    int limit = 50,
    int offset = 0,
    String? entityType,
    String? action,
    String? fromDate,
    String? toDate,
  }) async {
    final Database db = await _databaseService.database;

    String whereClause = '';
    final List<dynamic> whereArgs = [];

    if (entityType != null) {
      whereClause += 'a.entity_type = ?';
      whereArgs.add(entityType);
    }
    if (action != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'a.action = ?';
      whereArgs.add(action);
    }
    if (fromDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'a.created_at >= ?';
      whereArgs.add(fromDate);
    }
    if (toDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'a.created_at <= ?';
      whereArgs.add(toDate);
    }

    final String where = whereClause.isNotEmpty ? 'WHERE $whereClause' : '';

    return db.rawQuery(
      '''
      SELECT a.*, u.username 
      FROM audit_log a 
      LEFT JOIN users u ON a.user_id = u.id 
      $where
      ORDER BY a.created_at DESC 
      LIMIT ? OFFSET ?
      ''',
      [...whereArgs, limit, offset],
    );
  }

  /// Get login attempts with pagination.
  Future<List<Map<String, dynamic>>> getLoginAttempts({
    int limit = 50,
    int offset = 0,
  }) async {
    final Database db = await _databaseService.database;
    return db.query(
      'login_attempts',
      orderBy: 'attempted_at DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// Get audit log count.
  Future<int> getAuditLogCount() async {
    final Database db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM audit_log');
    return result.first['count'] as int;
  }

  /// Purge audit logs older than the given number of days.
  Future<int> purgeOldLogs(int retentionDays) async {
    final Database db = await _databaseService.database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .toIso8601String();

    final count = await db.delete(
      'audit_log',
      where: 'created_at < ?',
      whereArgs: [cutoff],
    );

    // Also purge old login attempts
    await db.delete(
      'login_attempts',
      where: 'attempted_at < ?',
      whereArgs: [cutoff],
    );

    return count;
  }

  /// Export audit log as CSV string.
  Future<String> exportAsCsv() async {
    final Database db = await _databaseService.database;
    final rows = await db.rawQuery('''
      SELECT a.*, u.username 
      FROM audit_log a 
      LEFT JOIN users u ON a.user_id = u.id 
      ORDER BY a.created_at DESC
    ''');

    final buffer = StringBuffer();
    buffer.writeln('ID,User,Action,Entity Type,Entity ID,Details,Timestamp');

    for (final row in rows) {
      buffer.writeln(
        '${row['id']},'
        '"${row['username'] ?? 'System'}",'
        '${row['action']},'
        '${row['entity_type']},'
        '${row['entity_id'] ?? ''},'
        '"${row['details'] ?? ''}",'
        '${row['created_at']}',
      );
    }

    return buffer.toString();
  }
}

/// Audit action types.
enum AuditAction {
  create,
  read,
  update,
  delete,
  login,
  logout,
  export,
  backup,
  restore,
  settingsChange,
  passwordChange,
  deviceBind,
  deviceTransfer,
}

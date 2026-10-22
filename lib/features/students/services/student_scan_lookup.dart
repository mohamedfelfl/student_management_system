import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../app/utils/qr_code_helper.dart';

/// Resolves a scanned QR payload or a typed serial to a single student row.
///
/// Returns null when nothing matches or when the input matches more than one
/// student, so attendance is never recorded against the wrong student.
class StudentScanLookup {
  static const String _selectStudent = '''
    SELECT s.*, g.name as group_name
    FROM students s
    LEFT JOIN groups g ON s.group_id = g.id
  ''';

  static Future<Map<String, Object?>?> find(
    DatabaseExecutor db,
    String rawScan,
  ) async {
    final String serial = QrCodeHelper.extractSerialNumber(rawScan);
    if (serial.isEmpty) return null;

    // 1. The exact serial printed on the card.
    final List<Map<String, Object?>> exact = await db.rawQuery(
      '$_selectStudent WHERE TRIM(s.serial_number) = ? COLLATE NOCASE',
      [serial],
    );
    if (exact.isNotEmpty) return exact.length == 1 ? exact.first : null;

    // 2. Other tokens of the payload (numeric part of a prefixed serial,
    // delimited segments, the raw input). A token never decides between two
    // students: an ambiguous match records nothing.
    final List<String> candidates = QrCodeHelper.extractAllCandidates(rawScan);
    if (candidates.isEmpty) return null;
    final String placeholders = List.filled(candidates.length, '?').join(',');
    final List<Map<String, Object?>> matches = await db.rawQuery(
      '$_selectStudent WHERE TRIM(s.serial_number) COLLATE NOCASE IN ($placeholders)',
      candidates,
    );
    return matches.length == 1 ? matches.first : null;
  }
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  // Update this path to match your actual DB path if different
  // On Windows, it's usually in %USERPROFILE%\Documents\StudentManagement\student_management.db
  final userProfile = Platform.environment['USERPROFILE']!;
  final dbPath = p.join(userProfile, 'OneDrive', 'المستندات', 'StudentManagement', 'student_management.db');
  
  print('Opening database at: $dbPath');
  
  if (!await File(dbPath).exists()) {
    print('Error: Database file not found at $dbPath');
    return;
  }

  final db = await databaseFactory.openDatabase(dbPath);
  
  print('\n--- Students and Groups ---');
  final students = await db.query('students');
  print('Total students: ${students.length}');
  
  int withGroup = 0;
  for (var s in students) {
    if (s['group_id'] != null) {
      withGroup++;
      print('Student: ${s['name']} (ID: ${s['id']}) -> Group ID: ${s['group_id']}');
    }
  }
  print('Students with groups: $withGroup');

  print('\n--- Groups ---');
  final groups = await db.query('groups');
  for (var g in groups) {
    print('Group: ${g['name']} (ID: ${g['id']})');
  }

  print('\n--- Exam Groups ---');
  final examGroups = await db.query('exam_groups');
  for (var eg in examGroups) {
    print('Exam ID: ${eg['exam_id']} -> Group ID: ${eg['group_id']}');
  }

  await db.close();
}

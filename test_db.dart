// ignore_for_file: avoid_print
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() async {
  sqfliteFfiInit();
  final dbPath = 'c:/Users/moham/Desktop/student_management_system/data.db'; // Adjust path if needed
  
  if (!File(dbPath).existsSync()) {
    print("Database not found at $dbPath");
    return;
  }
  
  var db = await databaseFactoryFfi.openDatabase(dbPath);
  var groups = await db.query('groups');
  var schedules = await db.query('group_schedules');
  
  print("Groups:");
  for (var g in groups) {
    print(g);
  }
  
  print("\nSchedules:");
  for (var s in schedules) {
    print(s);
  }
  
  await db.close();
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

void main() async {
  // Initialize FFI for Windows
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Attempt to find the DB path in Documents/StudentManagement
  final String? home = Platform.environment['USERPROFILE'];
  if (home == null) {
    print('Error: Could not find USERPROFILE environment variable.');
    return;
  }

  // Common path for getApplicationDocumentsDirectory() on Windows (localized/OneDrive)
  final String dbPath = p.join(home, 'OneDrive', 'المستندات', 'StudentManagement', 'student_management.db');

  print('Connecting to database at: $dbPath');
  if (!File(dbPath).existsSync()) {
    // Try fallback just in case
    final String fallbackPath = p.join(home, 'Documents', 'StudentManagement', 'student_management.db');
    if (!File(fallbackPath).existsSync()) {
      print('Error: Database file not found at $dbPath or $fallbackPath');
      return;
    }
  }

  Database? db;
  try {
    db = await openDatabase(dbPath);

    final List<String> firstNames = [
      'محمد', 'أحمد', 'ياسين', 'علي', 'عمر', 'محمود', 'مصطفى', 'يوسف', 'إبراهيم', 'زيد',
      'سارة', 'ليلى', 'نور', 'مريم', 'فاطمة', 'عائشة', 'جنى', 'هالة', 'منى', 'ريم'
    ];
    final List<String> lastNames = [
      'الأحمد', 'منصور', 'عبيد', 'القحطاني', 'المالكي', 'السيد', 'الحسن', 'النعيمي', 'زياد', 'العتيبي',
      'الحربي', 'الشمري', 'العنزي', 'الدوسري', 'الغامدي', 'الزهراني', 'الشهري', 'عسيري', 'القحطاني'
    ];
    final List<String> schools = [
      'مدرسة النور الدولية', 'مدرسة القدس الأهلية', 'مدرسة المستقبل', 'مدرسة المتفوقين النموذجية', 'مدرسة الأمل الابتدائية'
    ];
    final List<String> jobs = [
      'مهندس برمجيات', 'محاسب مالي', 'مدرس لغة عربية', 'طبيب أطفال', 'موظف حكومي', 'تاجر عقارات', 'محامي شرعي', 'طيار'
    ];

    final Random random = Random();

    print('Seeding 10 students...');
    for (int i = 0; i < 10; i++) {
      final String firstName = firstNames[random.nextInt(firstNames.length)];
      final String lastName = lastNames[random.nextInt(lastNames.length)];
      final String name = '$firstName $lastName';
      final String serial = '2024${(random.nextInt(900) + 100)}';
      final String school = schools[random.nextInt(schools.length)];
      final String job = jobs[random.nextInt(jobs.length)];
      final String phone = '05${random.nextInt(90000000) + 10000000}';

      await db.insert('students', {
        'serial_number': serial,
        'name': name,
        'address': 'الحي السكني، المنطقة ${random.nextInt(10) + 1}',
        'phone1': phone,
        'phone2': '',
        'father_job': job,
        'school': school,
        'previous_teacher': 'الأستاذ ${lastNames[random.nextInt(lastNames.length)]}',
        'group_id': null,
      });
      print('Inserted student $i: $name ($serial)');
    }

    print('Successfully inserted 10 students.');
  } catch (e) {
    print('Error during seeding: $e');
  } finally {
    await db?.close();
  }
}

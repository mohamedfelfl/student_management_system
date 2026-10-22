import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/authorization_service.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/assistants/cubits/assistant_attendance_cubit.dart';
import 'package:student_management_system/features/assistants/cubits/assistant_cubit.dart';
import 'package:student_management_system/features/attendance/cubits/attendance_cubit.dart';
import 'package:student_management_system/features/attendance/cubits/lesson_cubit.dart';
import 'package:student_management_system/features/attendance/models/attendance.dart';
import 'package:student_management_system/features/attendance/models/lesson.dart';
import 'package:student_management_system/features/auth/models/user.dart';
import 'package:student_management_system/features/exams/cubits/exam_cubit.dart';
import 'package:student_management_system/features/groups/cubits/group_cubit.dart';
import 'package:student_management_system/features/notes/cubits/notes_cubit.dart';
import 'package:student_management_system/features/payments/cubits/payment_cubit.dart';
import 'package:student_management_system/features/reports/cubits/report_cubit.dart';
import 'package:student_management_system/features/settings/cubits/settings_cubit.dart';
import 'package:student_management_system/features/settings/services/backup_service.dart';
import 'package:student_management_system/features/settings/services/device_binding_service.dart';
import 'package:student_management_system/features/settings/services/settings_service.dart';
import 'package:student_management_system/features/students/cubits/student_cubit.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

/// Everything a guarded action may need, built for one signed-in user.
class _Env {
  final Database db;
  final Directory documents;
  final AuthorizationService auth;
  late final DatabaseService dbService = _TestDatabaseService(db);
  late final StudentCubit students =
      StudentCubit(databaseService: dbService, authorization: auth);
  late final GroupCubit groups =
      GroupCubit(databaseService: dbService, authorization: auth);
  late final PaymentCubit payments =
      PaymentCubit(databaseService: dbService, authorization: auth);
  late final LessonCubit lessons =
      LessonCubit(databaseService: dbService, authorization: auth);
  late final AttendanceCubit attendance =
      AttendanceCubit(databaseService: dbService, authorization: auth);
  late final ReportCubit reports =
      ReportCubit(databaseService: dbService, authorization: auth);
  late final ExamCubit exams =
      ExamCubit(databaseService: dbService, authorization: auth);
  late final AssistantCubit assistants =
      AssistantCubit(databaseService: dbService, authorization: auth);
  late final AssistantAttendanceCubit assistantAttendance =
      AssistantAttendanceCubit(databaseService: dbService, authorization: auth);
  // NotesCubit starts loading in its constructor, so it is only built when a
  // test uses it, and that load is awaited before closing.
  NotesCubit? _notes;
  NotesCubit get notes =>
      _notes ??= NotesCubit(databaseService: dbService, authorization: auth);
  late final BackupService backup = BackupService(
    databaseService: dbService,
    documentsDirectory: () async => documents,
  );
  late final SettingsCubit settings = SettingsCubit(
    settingsService: SettingsService(databaseService: dbService),
    backupService: backup,
    deviceBindingService: DeviceBindingService(),
    authorization: auth,
  );

  _Env(this.db, this.documents, this.auth);

  Future<void> close() async {
    await students.close();
    await groups.close();
    await payments.close();
    await lessons.close();
    await attendance.close();
    await reports.close();
    await exams.close();
    await assistants.close();
    await assistantAttendance.close();
    final NotesCubit? notes = _notes;
    if (notes != null) {
      await notes.loadNotes();
      await notes.close();
    }
    await settings.close();
  }
}

const Lesson _activeLesson = Lesson(
  id: 1,
  groupId: 1,
  date: '2026-10-15',
  startTime: '10:00',
  status: LessonStatus.inProgress,
);

class _Case {
  final UserPermission permission;
  final String action;
  final Future<void> Function(_Env env) run;

  const _Case(this.permission, this.action, this.run);
}

final List<_Case> _cases = [
  _Case(UserPermission.manageStudents, 'create a student',
      (e) => e.students.createStudent({'name': 'طالب جديد', 'grade': 'sec_1'})),
  _Case(UserPermission.manageStudents, 'edit a student',
      (e) => e.students.updateStudent(1, {'name': 'اسم آخر'})),
  _Case(UserPermission.manageStudents, 'delete a student',
      (e) => e.students.deleteStudent(1)),
  _Case(UserPermission.manageStudents, 'delete several students',
      (e) => e.students.deleteMultipleStudents({1, 2})),
  _Case(UserPermission.manageStudents, 'merge students',
      (e) => e.students.mergeStudents(primaryId: 1, duplicateIds: [2])),
  _Case(UserPermission.manageGroups, 'create a group',
      (e) => e.groups.createGroup({'name': 'مجموعة جديدة', 'grade': 'sec_1'})),
  _Case(UserPermission.manageGroups, 'edit a group',
      (e) => e.groups.updateGroup(1, {'name': 'اسم آخر'})),
  _Case(UserPermission.manageGroups, 'delete a group',
      (e) => e.groups.deleteGroup(1)),
  _Case(UserPermission.manageGroups, 'add a student to a group',
      (e) => e.groups.linkStudentToGroup(3, 1)),
  _Case(UserPermission.manageGroups, 'remove a student from a group',
      (e) => e.groups.unlinkStudentFromGroup(1, 1)),
  _Case(UserPermission.managePayments, 'record a payment',
      (e) => e.payments.addPaymentTransaction(
          studentId: 1, month: 10, year: 2026, totalAmount: 200, paidAmount: 50)),
  _Case(UserPermission.managePayments, 'edit a payment',
      (e) => e.payments.updatePayment(1, {'paid_amount': 999.0})),
  _Case(UserPermission.managePayments, 'delete a payment',
      (e) => e.payments.deletePayment(1, 1)),
  _Case(UserPermission.manageAttendance, 'start a lesson',
      (e) => e.lessons.startLesson(
          const Lesson(groupId: 1, date: '2026-10-22', startTime: '12:00'))),
  _Case(UserPermission.manageAttendance, 'scan a card into the active lesson',
      (e) async {
    e.lessons.setActiveLesson(_activeLesson);
    await e.lessons.recordScanInActiveLesson('EL-01-00002');
  }),
  _Case(UserPermission.manageAttendance, 'mark a student present', (e) async {
    e.lessons.setActiveLesson(_activeLesson);
    await e.lessons.markStudentPresent(2);
  }),
  _Case(UserPermission.manageAttendance, 'remove an attendance record',
      (e) => e.lessons.removeAttendanceRecord(1)),
  _Case(UserPermission.manageAttendance, 'end a lesson',
      (e) => e.lessons.endLesson(1)),
  _Case(UserPermission.manageAttendance, 'add an extra lesson',
      (e) => e.lessons.createAdHocLesson(
          groupId: 1, date: DateTime(2026, 10, 23), startTime: '10:00')),
  _Case(UserPermission.manageAttendance, 'edit a lesson',
      (e) => e.lessons.updateLesson(
          lessonId: 1, groupId: 1, date: DateTime(2026, 10, 30), startTime: '11:00')),
  _Case(UserPermission.manageAttendance, 'delete a lesson',
      (e) => e.lessons.deleteLesson(1)),
  _Case(UserPermission.manageAttendance, 'record attendance by serial',
      (e) => e.attendance.recordAttendanceBySerial('EL-01-00002')),
  _Case(UserPermission.manageAttendance, 'add an attendance record',
      (e) => e.attendance.addAttendance(
          studentId: 2, date: DateTime(2026, 10, 22), status: AttendanceStatus.attended)),
  _Case(UserPermission.manageAttendance, 'edit an attendance record',
      (e) => e.attendance.updateAttendance(1, AttendanceStatus.missed)),
  _Case(UserPermission.manageAttendance, 'delete an attendance record',
      (e) => e.attendance.deleteAttendance(1)),
  _Case(UserPermission.manageExams, 'create an exam',
      (e) => e.exams.createExam(
          {'name': 'امتحان جديد', 'full_mark': 20.0, 'date': '2026-10-22'},
          groupIds: [1])),
  _Case(UserPermission.manageExams, 'edit an exam',
      (e) => e.exams.updateExam(1, {'name': 'اسم آخر'}, groupIds: [1])),
  _Case(UserPermission.manageExams, 'delete an exam',
      (e) => e.exams.deleteExam(1)),
  _Case(UserPermission.manageExams, 'enter a mark',
      (e) => e.exams.saveMark(examId: 1, studentId: 2, score: 10)),
  _Case(UserPermission.manageExams, 'save the marks sheet',
      (e) => e.exams.saveMarks(1, {2: 12}, clearedStudentIds: [1])),
  _Case(UserPermission.manageExams, 'auto-save the marks sheet',
      (e) => e.exams.saveMarksQuietly(1, {2: 12}, clearedStudentIds: [1])),
  _Case(UserPermission.manageExams, 'delete a mark',
      (e) => e.exams.deleteMark(examId: 1, studentId: 1)),
  _Case(UserPermission.manageAssistants, 'add an assistant',
      (e) => e.assistants.createAssistant(
          {'serial_number': 'AS-2', 'name': 'مساعد جديد'})),
  _Case(UserPermission.manageAssistants, 'edit an assistant',
      (e) => e.assistants.updateAssistant(1, {'name': 'اسم آخر'})),
  _Case(UserPermission.manageAssistants, 'delete an assistant',
      (e) => e.assistants.deleteAssistant(1)),
  _Case(UserPermission.manageAssistants, 'delete several assistants',
      (e) => e.assistants.deleteMultipleAssistants({1})),
  _Case(UserPermission.manageAssistants, 'record assistant attendance',
      (e) => e.assistantAttendance.recordAttendance(1, 'in')),
  _Case(UserPermission.manageAssistants, 'delete assistant attendance',
      (e) => e.assistantAttendance.deleteAttendance(1, 1)),
  _Case(UserPermission.manageNotes, 'add a study note',
      (e) => e.notes.addNote('مذكرة جديدة', 30)),
  _Case(UserPermission.manageNotes, 'edit a study note',
      (e) => e.notes.updateNote(1, 'اسم آخر', 99)),
  _Case(UserPermission.manageNotes, 'delete a study note',
      (e) => e.notes.deleteNote(1)),
  _Case(UserPermission.manageNotes, 'record note deliveries', (e) async {
    e.notes.selectNoteForDelivery(1);
    await e.notes.loadDeliveries(1);
    e.notes.updateDeliveryStatusLocal(2, true);
    e.notes.updateDeliveryStatusLocal(1, false);
    await e.notes.saveDeliveries();
  }),
];

/// Settings actions that the app shows only to admins (database section).
final Map<String, Future<void> Function(_Env env)> _adminOnly = {
  'reset all data': (e) => e.settings.resetAllData(),
  'purge old data': (e) => e.settings.purgeOldData(1),
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late Directory documents;

  Future<void> createSchema() async {
    for (final String sql in [
      DBQueries.createUsersTable,
      DBQueries.createGroupsTable,
      DBQueries.createGroupSchedulesTable,
      DBQueries.createStudentsTable,
      DBQueries.createPaymentsTable,
      DBQueries.createLessonsTable,
      DBQueries.createAttendanceTable,
      DBQueries.createAssistantsTable,
      DBQueries.createAssistantAttendanceTable,
      DBQueries.createExamsTable,
      DBQueries.createExamGroupsTable,
      DBQueries.createMarksTable,
      DBQueries.createNotesTable,
      DBQueries.createStudentNotesTable,
      DBQueries.createAppSettingsTable,
      DBQueries.createDeviceBindingTable,
      DBQueries.createLoginAttemptsTable,
    ]) {
      await db.execute(sql);
    }
  }

  Future<void> seed() async {
    await db.insert('groups', {'id': 1, 'name': 'السبت', 'grade': 'sec_1'});
    await db.insert('students', {'id': 1, 'serial_number': 'EL-01-00001', 'name': 'أحمد', 'group_id': 1, 'grade': 'sec_1'});
    await db.insert('students', {'id': 2, 'serial_number': 'EL-01-00002', 'name': 'منى', 'group_id': 1, 'grade': 'sec_1'});
    await db.insert('students', {'id': 3, 'serial_number': 'EL-01-00003', 'name': 'كريم', 'grade': 'sec_1'});
    await db.insert('payments', {'id': 1, 'student_id': 1, 'month': 10, 'year': 2026, 'total_amount': 200.0, 'paid_amount': 100.0, 'paid_date': '2026-10-01'});
    await db.insert('lessons', {'id': 1, 'group_id': 1, 'date': '2026-10-15', 'start_time': '10:00', 'status': 'inProgress'});
    await db.insert('attendance', {'id': 1, 'lesson_id': 1, 'student_id': 1, 'date': '2026-10-15', 'status': 'attended'});
    await db.insert('attendance', {'id': 2, 'student_id': 2, 'date': '2019-01-01', 'status': 'attended'});
    await db.insert('exams', {'id': 1, 'name': 'شهر أكتوبر', 'full_mark': 20.0, 'date': '2026-10-01'});
    await db.insert('exam_groups', {'exam_id': 1, 'group_id': 1});
    await db.insert('marks', {'id': 1, 'exam_id': 1, 'student_id': 1, 'score': 15.0});
    await db.insert('assistants', {'id': 1, 'serial_number': 'AS-1', 'name': 'مساعد'});
    await db.insert('assistant_attendance', {'id': 1, 'assistant_id': 1, 'date': '2026-10-15', 'type': 'in'});
    await db.insert('notes', {'id': 1, 'name': 'مذكرة الوحدة الأولى', 'price': 25.0});
    await db.insert('student_notes', {'id': 1, 'student_id': 1, 'note_id': 1, 'delivered_date': '2026-10-01'});
  }

  Future<Map<String, List<Map<String, Object?>>>> snapshot() async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );
    return {
      for (final t in tables)
        t['name'] as String: await db.rawQuery('SELECT * FROM "${t['name']}" ORDER BY rowid'),
    };
  }

  AuthorizationService signedInWith(List<UserPermission> permissions) =>
      AuthorizationService()
        ..signIn(User(
          id: 9,
          username: 'staff',
          passwordHash: 'x',
          permissions: permissions,
        ));

  AuthorizationService signedInWithout(UserPermission missing) => signedInWith(
        UserPermission.values.where((p) => p != missing).toList(),
      );

  /// A user (not an admin) who holds every permission.
  AuthorizationService signedInAsStaffWithEveryPermission() =>
      signedInWith(UserPermission.values);

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys = ON');
    await createSchema();
    await seed();
    documents = await Directory.systemTemp.createTemp('guards_test');
  });

  tearDown(() async {
    await db.close();
    await documents.delete(recursive: true);
  });

  for (final _Case c in _cases) {
    test('without ${c.permission.name}, a user cannot ${c.action}', () async {
      final env = _Env(db, documents, signedInWithout(c.permission));
      final before = await snapshot();

      try {
        await c.run(env);
      } catch (_) {
        // Refusal may surface as an exception or as an error state.
      }

      expect(await snapshot(), before);
      await env.close();
    });
  }

  for (final MapEntry<String, Future<void> Function(_Env)> action
      in _adminOnly.entries) {
    test('a user who is not an admin cannot ${action.key}', () async {
      final env = _Env(db, documents, signedInAsStaffWithEveryPermission());
      final before = await snapshot();

      try {
        await action.value(env);
      } catch (_) {}

      expect(await snapshot(), before);
      await env.close();
    });
  }

  test('a user who is not an admin cannot delete a backup file', () async {
    final env = _Env(db, documents, signedInAsStaffWithEveryPermission());
    final backupDir = Directory(p.join(documents.path, 'StudentManagement', 'Backups'))
      ..createSync(recursive: true);
    final backupFile = File(p.join(backupDir.path, 'backup_keep.db'))
      ..writeAsStringSync('backup');

    await env.settings.deleteBackup(backupFile.path);

    expect(backupFile.existsSync(), isTrue);
    await env.close();
  });

  test('a user who is not an admin cannot export data to CSV', () async {
    final env = _Env(db, documents, signedInAsStaffWithEveryPermission());

    await env.settings.exportCsv('students');

    final backupDir = Directory(p.join(documents.path, 'StudentManagement', 'Backups'));
    final csvFiles = backupDir.existsSync()
        ? backupDir.listSync().where((f) => f.path.endsWith('.csv')).toList()
        : <FileSystemEntity>[];
    expect(csvFiles, isEmpty);
    await env.close();
  });

  test('without viewReports, a user cannot generate a report', () async {
    final env = _Env(db, documents, signedInWithout(UserPermission.viewReports));

    await env.reports.generateStudentReport(1);

    expect(env.reports.state.pdfDocument, isNull);
    expect(env.reports.state.error, isNotNull);
    await env.close();
  });

  test('a user with manageStudents can still delete a student', () async {
    final env = _Env(db, documents, signedInWith([UserPermission.manageStudents]));

    await env.students.deleteStudent(3);

    expect(await db.query('students', where: 'id = 3'), isEmpty);
    await env.close();
  });

  test('a user with manageExams can still enter a mark', () async {
    final env = _Env(db, documents, signedInWith([UserPermission.manageExams]));

    await env.exams.saveMark(examId: 1, studentId: 2, score: 11);

    expect(
      await db.query('marks', where: 'exam_id = 1 AND student_id = 2'),
      hasLength(1),
    );
    await env.close();
  });

  test('a user with manageNotes can still add a study note', () async {
    final env = _Env(db, documents, signedInWith([UserPermission.manageNotes]));

    await env.notes.addNote('مذكرة جديدة', 30);

    expect(await db.query('notes'), hasLength(2));
    await env.close();
  });

  test('an admin can still delete a backup file', () async {
    final auth = AuthorizationService()
      ..signIn(const User(
        id: 1,
        username: 'admin',
        passwordHash: 'x',
        role: UserRole.admin,
      ));
    final env = _Env(db, documents, auth);
    final backupDir = Directory(p.join(documents.path, 'StudentManagement', 'Backups'))
      ..createSync(recursive: true);
    final backupFile = File(p.join(backupDir.path, 'backup_old.db'))
      ..writeAsStringSync('backup');

    await env.settings.deleteBackup(backupFile.path);

    expect(backupFile.existsSync(), isFalse);
    await env.close();
  });
}

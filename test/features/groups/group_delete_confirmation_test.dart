import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/groups/cubits/group_cubit.dart';
import 'package:student_management_system/features/groups/screens/group_list/components/group_card.dart';
import 'package:student_management_system/generated/codegen_loader.g.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

/// Records deletions instead of touching a database, so the widget tests can
/// check the confirmation flow without real async I/O.
class _RecordingGroupCubit extends GroupCubit {
  final List<int> deletedIds = [];

  _RecordingGroupCubit()
      : super(databaseService: DatabaseService(encryptionService: EncryptionService()));

  @override
  Future<GroupDeletionImpact> getDeletionImpact(int groupId) async =>
      const GroupDeletionImpact(lessons: 2, attendanceRecords: 3, students: 4);

  @override
  Future<void> deleteGroup(int id) async => deletedIds.add(id);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('GroupCubit.getDeletionImpact', () {
    late Database db;
    late GroupCubit cubit;

    setUp(() async {
      db = await databaseFactory.openDatabase(inMemoryDatabasePath);
      await db.execute(DBQueries.createGroupsTable);
      await db.execute(DBQueries.createGroupSchedulesTable);
      await db.execute(DBQueries.createStudentsTable);
      await db.execute(DBQueries.createLessonsTable);
      await db.execute(DBQueries.createAttendanceTable);

      await db.insert('groups', {'id': 1, 'name': 'السبت'});
      await db.insert('groups', {'id': 2, 'name': 'الأحد'});
      await db.insert('students', {'id': 1, 'serial_number': 'EL-01-00001', 'name': 'أ', 'group_id': 1});
      await db.insert('students', {'id': 2, 'serial_number': 'EL-01-00002', 'name': 'ب', 'group_id': 1});
      await db.insert('students', {'id': 3, 'serial_number': 'EL-01-00003', 'name': 'ج', 'group_id': 2});
      await db.insert('lessons', {'id': 1, 'group_id': 1, 'date': '2026-10-01', 'start_time': '10:00'});
      await db.insert('lessons', {'id': 2, 'group_id': 1, 'date': '2026-10-08', 'start_time': '10:00'});
      await db.insert('lessons', {'id': 3, 'group_id': 2, 'date': '2026-10-02', 'start_time': '12:00'});
      await db.insert('attendance', {'lesson_id': 1, 'student_id': 1, 'date': '2026-10-01'});
      await db.insert('attendance', {'lesson_id': 1, 'student_id': 2, 'date': '2026-10-01'});
      await db.insert('attendance', {'lesson_id': 2, 'student_id': 1, 'date': '2026-10-08'});
      await db.insert('attendance', {'lesson_id': 3, 'student_id': 3, 'date': '2026-10-02'});

      cubit = GroupCubit(databaseService: _TestDatabaseService(db));
    });

    tearDown(() async {
      await cubit.close();
      await db.close();
    });

    test('counts the lessons, attendance and students of that group only',
        () async {
      final impact = await cubit.getDeletionImpact(1);

      expect(impact.lessons, 2);
      expect(impact.attendanceRecords, 3);
      expect(impact.students, 2);
    });
  });

  group('GroupCard delete', () {
    late _RecordingGroupCubit cubit;

    setUpAll(() async {
      const channel = MethodChannel('plugins.flutter.io/shared_preferences');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') return <String, dynamic>{};
        return true;
      });
      await EasyLocalization.ensureInitialized();
    });

    setUp(() => cubit = _RecordingGroupCubit());
    tearDown(() => cubit.close());

    Future<void> openDeleteFromMenu(WidgetTester tester) async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar')],
          path: 'assets/translations',
          startLocale: const Locale('ar'),
          fallbackLocale: const Locale('ar'),
          assetLoader: const CodegenLoader(),
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Scaffold(
                body: BlocProvider<GroupCubit>.value(
                  value: cubit,
                  child: const GroupCard(
                    group: {'id': 1, 'name': 'السبت', 'student_count': 4},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف').last);
      await tester.pumpAndSettle();
    }

    testWidgets('shows how much attendance history will be lost',
        (tester) async {
      await openDeleteFromMenu(tester);

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('2 حصة و3 سجل حضور'), findsOneWidget);
      expect(cubit.deletedIds, isEmpty);
    });

    testWidgets('cancelling keeps the group', (tester) async {
      await openDeleteFromMenu(tester);

      await tester.tap(find.byKey(GroupCard.cancelDeleteKey));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(cubit.deletedIds, isEmpty);
    });

    testWidgets('confirming deletes the group', (tester) async {
      await openDeleteFromMenu(tester);

      await tester.tap(find.byKey(GroupCard.confirmDeleteKey));
      await tester.pumpAndSettle();

      expect(cubit.deletedIds, [1]);
    });
  });
}

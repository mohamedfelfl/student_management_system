import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/features/qr_card_generator/data/models/qr_card_config.dart';
import 'package:student_management_system/features/qr_card_generator/data/models/student_card_data.dart';
import 'package:student_management_system/features/qr_card_generator/domain/repositories/iqr_card_repository.dart';
import 'package:student_management_system/features/qr_card_generator/presentation/cubits/qr_card_cubit.dart';

class MockQrCardRepository implements IQrCardRepository {
  final List<StudentCardData> mockStudents;
  final List<Map<String, Object?>> mockGroups;
  final List<String> mockStages;

  MockQrCardRepository({
    required this.mockStudents,
    required this.mockGroups,
    required this.mockStages,
  });

  @override
  Future<List<StudentCardData>> getStudentsForCards() async => mockStudents;

  @override
  Future<List<Map<String, Object?>>> getGroups() async => mockGroups;

  @override
  Future<List<String>> getStages() async => mockStages;
}

void main() {
  group('StudentCardData Model Tests', () {
    test('fromMap parses raw database map correctly', () {
      final rawMap = {
        'id': 101,
        'serial_number': 'EM000101',
        'name': 'إياد أحمد صبري',
        'grade': 'prep_1',
        'group_name': 'المجموعة 12',
        'attendance_day': 'السبت و الثلاثاء الساعة 12',
      };

      final studentCard = StudentCardData.fromMap(rawMap);

      expect(studentCard.id, equals(101));
      expect(studentCard.studentCode, equals('EM000101'));
      expect(studentCard.fullName, equals('إياد أحمد صبري'));
      expect(studentCard.groupSchedule, equals('السبت و الثلاثاء الساعة 12'));
      expect(studentCard.qrPayload, equals('EM000101'));
    });

    test('QRCardConfig copyWith maintains immutability', () {
      const initialConfig = QRCardConfig();
      expect(initialConfig.selectionMode, equals(QRCardSelectionMode.student));
      expect(initialConfig.searchQuery, isEmpty);

      final updatedConfig = initialConfig.copyWith(
        selectionMode: QRCardSelectionMode.group,
        searchQuery: 'علي',
      );

      expect(updatedConfig.selectionMode, equals(QRCardSelectionMode.group));
      expect(updatedConfig.searchQuery, equals('علي'));
    });
  });

  group('QrCardCubit Clean Architecture Tests', () {
    late MockQrCardRepository repository;
    late QrCardCubit cubit;

    final mockStudents = [
      const StudentCardData(
        id: 1,
        studentCode: 'EM000001',
        fullName: 'أحمد علي',
        stageName: 'الصف الأول الثانوي',
        groupName: 'مجموعة أ',
        qrPayload: 'EM000001',
      ),
      const StudentCardData(
        id: 2,
        studentCode: 'EM000002',
        fullName: 'محمود حسن',
        stageName: 'الصف الثاني الثانوي',
        groupName: 'مجموعة ب',
        qrPayload: 'EM000002',
      ),
    ];

    setUp(() {
      repository = MockQrCardRepository(
        mockStudents: mockStudents,
        mockGroups: [
          {'id': 1, 'name': 'مجموعة أ'},
          {'id': 2, 'name': 'مجموعة ب'},
        ],
        mockStages: ['الصف الأول الثانوي', 'الصف الثاني الثانوي'],
      );
      cubit = QrCardCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('loadInitialData populates state from repository', () async {
      await cubit.loadInitialData();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.allStudents.length, equals(2));
      expect(cubit.state.availableGroups.length, equals(2));
      expect(cubit.state.availableStages.length, equals(2));
      expect(cubit.state.activePreviewStudent?.id, equals(1));
    });

    test('updateSearchQuery filters student list cleanly', () async {
      await cubit.loadInitialData();
      cubit.updateSearchQuery('محمود');

      expect(cubit.state.filteredStudents.length, equals(1));
      expect(cubit.state.filteredStudents.first.fullName, equals('محمود حسن'));
    });
  });
}

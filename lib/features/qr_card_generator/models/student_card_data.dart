import 'package:freezed_annotation/freezed_annotation.dart';

part 'student_card_data.freezed.dart';
part 'student_card_data.g.dart';

@freezed
abstract class StudentCardData with _$StudentCardData {
  const factory StudentCardData({
    required int id,
    required String studentCode,
    required String fullName,
    @Default('الصف الأول الإعدادي') String stageName,
    @Default('') String groupName,
    @Default('') String groupSchedule,
    required String qrPayload,
  }) = _StudentCardData;

  factory StudentCardData.fromJson(Map<String, dynamic> json) =>
      _$StudentCardDataFromJson(json);

  static String formatStageArabic(String? grade) {
    if (grade == null || grade.trim().isEmpty) return 'الصف الأول الإعدادي';
    switch (grade.trim()) {
      case 'primary_1':
        return 'الصف الأول الابتدائي';
      case 'primary_2':
        return 'الصف الثاني الابتدائي';
      case 'primary_3':
        return 'الصف الثالث الابتدائي';
      case 'primary_4':
        return 'الصف الرابع الابتدائي';
      case 'primary_5':
        return 'الصف الخامس الابتدائي';
      case 'primary_6':
        return 'الصف السادس الابتدائي';
      case 'prep_1':
        return 'الصف الأول الإعدادي';
      case 'prep_2':
        return 'الصف الثاني الإعدادي';
      case 'prep_3':
        return 'الصف الثالث الإعدادي';
      case 'sec_1':
        return 'الصف الأول الثانوي';
      case 'sec_2':
        return 'الصف الثاني الثانوي';
      case 'sec_3':
        return 'الصف الثالث الثانوي';
      default:
        return grade;
    }
  }

  factory StudentCardData.fromMap(Map<String, dynamic> map) {
    final serial = map['serial_number'] as String? ?? '';
    final code = serial.isNotEmpty
        ? serial
        : 'EM${(map['id'] as int? ?? 0).toString().padLeft(6, '0')}';
    
    final rawGrade = map['grade'] as String? ?? map['stage_name'] as String? ?? '';

    return StudentCardData(
      id: map['id'] as int? ?? 0,
      studentCode: code,
      fullName: map['name'] as String? ?? 'طالب',
      stageName: formatStageArabic(rawGrade),
      groupName: map['group_name'] as String? ?? '',
      groupSchedule: map['attendance_day'] as String? ?? map['group_schedule'] as String? ?? '',
      qrPayload: code,
    );
  }
}

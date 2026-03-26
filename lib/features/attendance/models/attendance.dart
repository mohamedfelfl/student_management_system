import 'package:freezed_annotation/freezed_annotation.dart';

part 'attendance.freezed.dart';
part 'attendance.g.dart';

/// Attendance status for a lesson.
enum AttendanceStatus {
  attended,
  missed,
  /// Student attended a different lesson (not their assigned group)
  otherLesson,
}

@freezed
abstract class Attendance with _$Attendance {
  const factory Attendance({
    int? id,
    required int studentId,
    required DateTime date,
    required AttendanceStatus status,
    /// Optional notes (e.g., which other lesson was attended)
    @Default('') String notes,
  }) = _Attendance;

  factory Attendance.fromJson(Map<String, dynamic> json) => _$AttendanceFromJson(json);
}

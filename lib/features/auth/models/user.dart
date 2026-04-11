import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User roles in the system.
enum UserRole {
  admin,
  user,
}

/// Permissions that can be assigned to users.
enum UserPermission {
  manageStudents,
  manageGroups,
  managePayments,
  manageAttendance,
  manageExams,
  viewReports,
  manageUsers,
  manageAssistants,
  manageNotes,
}

@freezed
abstract class User with _$User {
  const factory User({
    int? id,
    required String username,
    required String passwordHash,
    @Default(UserRole.user) UserRole role,
    @Default([]) List<UserPermission> permissions,
    DateTime? createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

extension UserX on User {
  /// Checks if the user has a specific permission or is an admin.
  bool can(UserPermission permission) {
    if (role == UserRole.admin) return true;
    return permissions.contains(permission);
  }
}

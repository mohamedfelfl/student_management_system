import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// User roles in the system.
enum UserRole { admin, user }

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

/// Parses the JSON list stored in `users.permissions`. Names that are not a
/// known permission (e.g. removed in a later version) are ignored rather than
/// mapped to some other permission.
List<UserPermission> parseUserPermissions(Object? storedJson) {
  if (storedJson is! String || storedJson.isEmpty) return [];
  final Object? decoded = jsonDecode(storedJson);
  if (decoded is! List) return [];
  return [
    for (final UserPermission p in UserPermission.values)
      if (decoded.contains(p.name)) p,
  ];
}

extension UserX on User {
  /// Checks if the user has a specific permission or is an admin.
  bool can(UserPermission permission) {
    if (role == UserRole.admin) return true;
    return permissions.contains(permission);
  }
}

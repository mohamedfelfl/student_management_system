import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/di/injection.dart';
import 'package:student_management_system/app/services/authorization_service.dart';
import 'package:student_management_system/features/auth/models/user.dart';

void main() {
  const User clerk = User(
    id: 2,
    username: 'clerk',
    passwordHash: 'x',
    permissions: [UserPermission.managePayments],
  );
  const User admin = User(
    id: 1,
    username: 'admin',
    passwordHash: 'x',
    role: UserRole.admin,
  );

  test('nobody is allowed anything before signing in', () {
    final auth = AuthorizationService();

    expect(
      () => auth.require(UserPermission.managePayments),
      throwsA(isA<PermissionDeniedException>()),
    );
  });

  test('a user is allowed only the permissions they were given', () {
    final auth = AuthorizationService()..signIn(clerk);

    auth.require(UserPermission.managePayments);
    expect(
      () => auth.require(UserPermission.manageStudents),
      throwsA(isA<PermissionDeniedException>()),
    );
  });

  test('an admin is allowed everything', () {
    final auth = AuthorizationService()..signIn(admin);

    auth.require(UserPermission.manageUsers);
    auth.requireAdmin();
  });

  test('a non-admin fails requireAdmin', () {
    final auth = AuthorizationService()..signIn(clerk);

    expect(auth.requireAdmin, throwsA(isA<PermissionDeniedException>()));
  });

  test('the app registers a service that allows nothing before sign-in',
      () async {
    await configureDependencies();
    addTearDown(getIt.reset);

    expect(resolveAuthorization(null).can(UserPermission.manageStudents), isFalse);
  });

  test('signing out removes all permissions', () {
    final auth = AuthorizationService()..signIn(admin);

    auth.signOut();

    expect(auth.requireAdmin, throwsA(isA<PermissionDeniedException>()));
  });
}

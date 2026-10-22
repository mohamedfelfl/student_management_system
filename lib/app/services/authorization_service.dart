import 'package:easy_localization/easy_localization.dart';

import '../../features/auth/models/user.dart';
import '../../generated/locale_keys.g.dart';
import '../di/injection.dart';

/// The app's [AuthorizationService], or an unrestricted one when the app's
/// dependencies are not set up (code that builds cubits directly, e.g. tests).
AuthorizationService resolveAuthorization(AuthorizationService? given) {
  if (given != null) return given;
  return getIt.isRegistered<AuthorizationService>()
      ? getIt<AuthorizationService>()
      : AuthorizationService.unrestricted();
}

/// Holds the signed-in user and enforces permissions inside cubits, so a
/// hidden menu item is not the only thing between a user and an action.
class AuthorizationService {
  final bool _unrestricted;
  User? _currentUser;

  AuthorizationService() : _unrestricted = false;

  /// Allows everything. Only for code paths that run without the app's
  /// dependency setup (tests and tooling); the app registers the restricted
  /// service in `configureDependencies`.
  AuthorizationService.unrestricted() : _unrestricted = true;

  User? get currentUser => _currentUser;

  bool get isAdmin => _unrestricted || _currentUser?.role == UserRole.admin;

  void signIn(User user) => _currentUser = user;

  void signOut() => _currentUser = null;

  bool can(UserPermission permission) =>
      _unrestricted || (_currentUser?.can(permission) ?? false);

  /// Throws [PermissionDeniedException] unless the signed-in user has
  /// [permission] (admins have every permission).
  void require(UserPermission permission) {
    if (!can(permission)) throw PermissionDeniedException();
  }

  /// Throws [PermissionDeniedException] unless the signed-in user is an admin.
  void requireAdmin() {
    if (!isAdmin) {
      throw PermissionDeniedException(LocaleKeys.only_admin_can_manage_admins);
    }
  }
}

/// An action was refused because of the signed-in user's role or permissions.
class PermissionDeniedException implements Exception {
  /// Translation key of the message shown to the user.
  final String messageKey;

  PermissionDeniedException([this.messageKey = LocaleKeys.permission_denied]);

  @override
  String toString() => messageKey.tr();
}

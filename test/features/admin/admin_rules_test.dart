import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:student_management_system/app/constants/db_queries.dart';
import 'package:student_management_system/app/services/authorization_service.dart';
import 'package:student_management_system/app/services/database_service.dart';
import 'package:student_management_system/app/services/encryption_service.dart';
import 'package:student_management_system/features/admin/cubits/admin_cubit.dart';
import 'package:student_management_system/features/auth/cubits/auth_cubit.dart';
import 'package:student_management_system/features/auth/models/user.dart';

class _TestDatabaseService extends DatabaseService {
  final Database _db;
  _TestDatabaseService(this._db)
      : super(encryptionService: EncryptionService());

  @override
  Future<Database> get database async => _db;
}

const User _admin = User(id: 1, username: 'admin', passwordHash: 'x', role: UserRole.admin);
const User _manager = User(
  id: 2,
  username: 'manager',
  passwordHash: 'x',
  permissions: [UserPermission.manageUsers],
);
const User _clerk = User(
  id: 3,
  username: 'clerk',
  passwordHash: 'x',
  permissions: [UserPermission.managePayments],
);

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late AuthorizationService auth;

  Future<void> insertUser(int id, String username, String role,
      {List<String> permissions = const []}) async {
    final (hash, salt) = AuthCubit.hashPasswordWithSalt('secret123');
    await db.insert('users', {
      'id': id,
      'username': username,
      'password_hash': hash,
      'salt': salt,
      'role': role,
      'permissions': jsonEncode(permissions),
    });
  }

  Future<Map<String, Object?>?> userRow(Object idOrName) async {
    final rows = idOrName is int
        ? await db.query('users', where: 'id = ?', whereArgs: [idOrName])
        : await db.query('users', where: 'username = ?', whereArgs: [idOrName]);
    return rows.isEmpty ? null : rows.first;
  }

  AdminCubit cubitAs(User user) => AdminCubit(
        databaseService: _TestDatabaseService(db),
        authorization: auth..signIn(user),
      );

  setUp(() async {
    db = await databaseFactory.openDatabase(inMemoryDatabasePath);
    await db.execute(DBQueries.createUsersTable);
    await insertUser(1, 'admin', 'admin');
    await insertUser(2, 'manager', 'user', permissions: ['manageUsers']);
    await insertUser(3, 'clerk', 'user', permissions: ['managePayments']);
    auth = AuthorizationService();
  });

  tearDown(() async => db.close());

  group('a user who can manage users but is not an admin', () {
    test('can create a regular user', () async {
      await cubitAs(_manager).createUser(
        username: 'new_clerk',
        password: 'secret123',
        role: UserRole.user,
        permissions: const [UserPermission.managePayments],
      );

      expect((await userRow('new_clerk'))?['role'], 'user');
    });

    test('cannot create an admin', () async {
      final cubit = cubitAs(_manager);
      await cubit.createUser(
        username: 'sneaky_admin',
        password: 'secret123',
        role: UserRole.admin,
        permissions: const [],
      );

      expect(await userRow('sneaky_admin'), isNull);
      expect(cubit.state.error, isNotNull);
    });

    test('cannot promote anyone to admin, including themselves', () async {
      final cubit = cubitAs(_manager);
      await cubit.updateUser(id: 3, role: UserRole.admin);
      await cubit.updateUser(id: 2, role: UserRole.admin);

      expect((await userRow(3))?['role'], 'user');
      expect((await userRow(2))?['role'], 'user');
    });

    test("cannot change an admin's password", () async {
      final before = (await userRow(1))?['password_hash'];

      await cubitAs(_manager).updateUser(id: 1, password: 'taken-over');

      expect((await userRow(1))?['password_hash'], before);
    });

    test('cannot delete an admin', () async {
      await cubitAs(_manager).deleteUser(1);

      expect(await userRow(1), isNotNull);
    });
  });

  test('a user without the manage-users permission cannot create users',
      () async {
    await cubitAs(_clerk).createUser(
      username: 'friend',
      password: 'secret123',
      role: UserRole.user,
      permissions: const [UserPermission.manageStudents],
    );

    expect(await userRow('friend'), isNull);
  });

  test('nobody can delete the account they are signed in with', () async {
    await cubitAs(_manager).deleteUser(2);

    expect(await userRow(2), isNotNull);
  });

  test('the last admin cannot be changed to a regular user', () async {
    final cubit = cubitAs(_admin);
    await cubit.updateUser(id: 1, role: UserRole.user);

    expect((await userRow(1))?['role'], 'admin');
    expect(cubit.state.error, isNotNull);
  });

  test('an admin can remove another admin while one admin remains', () async {
    await insertUser(4, 'second_admin', 'admin');

    await cubitAs(_admin).deleteUser(4);

    expect(await userRow(4), isNull);
  });

  test('unknown permission names are ignored, not turned into another one',
      () async {
    await insertUser(5, 'old_account', 'user',
        permissions: ['managePayments', 'permissionRemovedInV2']);
    final cubit = cubitAs(_admin);

    await cubit.loadUsers();

    final User loaded = cubit.state.users.firstWhere((u) => u.id == 5);
    expect(loaded.permissions, [UserPermission.managePayments]);
  });

  group('AuthCubit', () {
    test('signing in sets the user used for permission checks', () async {
      final cubit = AuthCubit(
        databaseService: _TestDatabaseService(db),
        authorization: auth,
      );

      await cubit.login('manager', 'secret123');

      expect(auth.currentUser?.username, 'manager');
      await cubit.close();
    });

    test('signing out clears it', () async {
      final cubit = AuthCubit(
        databaseService: _TestDatabaseService(db),
        authorization: auth,
      );
      await cubit.login('manager', 'secret123');

      cubit.logout();

      expect(auth.currentUser, isNull);
      await cubit.close();
    });

    test('unknown permission names do not grant anything at sign-in', () async {
      await insertUser(6, 'legacy', 'user', permissions: ['permissionRemovedInV2']);
      final cubit = AuthCubit(
        databaseService: _TestDatabaseService(db),
        authorization: auth,
      );

      await cubit.login('legacy', 'secret123');

      expect(auth.currentUser?.permissions, isEmpty);
      await cubit.close();
    });
  });
}

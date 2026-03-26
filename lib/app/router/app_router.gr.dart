// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i21;
import 'package:flutter/material.dart' as _i22;
import 'package:student_management_system/app/shared/screens/shell_screen.dart'
    as _i16;
import 'package:student_management_system/features/admin/screens/admin_panel_screen.dart'
    as _i1;
import 'package:student_management_system/features/admin/screens/user_form_screen.dart'
    as _i20;
import 'package:student_management_system/features/attendance/screens/attendance_list_screen.dart'
    as _i2;
import 'package:student_management_system/features/attendance/screens/qr_scanner_screen.dart'
    as _i14;
import 'package:student_management_system/features/auth/screens/login_screen.dart'
    as _i10;
import 'package:student_management_system/features/dashboard/screens/dashboard_screen.dart'
    as _i3;
import 'package:student_management_system/features/exams/screens/exam_detail_screen.dart'
    as _i4;
import 'package:student_management_system/features/exams/screens/exam_form_screen.dart'
    as _i5;
import 'package:student_management_system/features/exams/screens/exam_list_screen.dart'
    as _i6;
import 'package:student_management_system/features/exams/screens/exams_management_screen.dart'
    as _i7;
import 'package:student_management_system/features/exams/screens/mark_entry_screen.dart'
    as _i11;
import 'package:student_management_system/features/groups/screens/group_form_screen.dart'
    as _i8;
import 'package:student_management_system/features/groups/screens/group_list_screen.dart'
    as _i9;
import 'package:student_management_system/features/payments/screens/payment_form_screen.dart'
    as _i12;
import 'package:student_management_system/features/payments/screens/payment_list_screen.dart'
    as _i13;
import 'package:student_management_system/features/reports/screens/report_screen.dart'
    as _i15;
import 'package:student_management_system/features/students/screens/student_detail_screen.dart'
    as _i17;
import 'package:student_management_system/features/students/screens/student_form_screen.dart'
    as _i18;
import 'package:student_management_system/features/students/screens/student_list_screen.dart'
    as _i19;

/// generated route for
/// [_i1.AdminPanelScreen]
class AdminPanelRoute extends _i21.PageRouteInfo<void> {
  const AdminPanelRoute({List<_i21.PageRouteInfo>? children})
    : super(AdminPanelRoute.name, initialChildren: children);

  static const String name = 'AdminPanelRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i1.AdminPanelScreen();
    },
  );
}

/// generated route for
/// [_i2.AttendanceListScreen]
class AttendanceListRoute extends _i21.PageRouteInfo<AttendanceListRouteArgs> {
  AttendanceListRoute({
    _i22.Key? key,
    int? studentId,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         AttendanceListRoute.name,
         args: AttendanceListRouteArgs(key: key, studentId: studentId),
         rawQueryParams: {'studentId': studentId},
         initialChildren: children,
       );

  static const String name = 'AttendanceListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<AttendanceListRouteArgs>(
        orElse: () =>
            AttendanceListRouteArgs(studentId: queryParams.optInt('studentId')),
      );
      return _i2.AttendanceListScreen(key: args.key, studentId: args.studentId);
    },
  );
}

class AttendanceListRouteArgs {
  const AttendanceListRouteArgs({this.key, this.studentId});

  final _i22.Key? key;

  final int? studentId;

  @override
  String toString() {
    return 'AttendanceListRouteArgs{key: $key, studentId: $studentId}';
  }
}

/// generated route for
/// [_i3.DashboardScreen]
class DashboardRoute extends _i21.PageRouteInfo<void> {
  const DashboardRoute({List<_i21.PageRouteInfo>? children})
    : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i3.DashboardScreen();
    },
  );
}

/// generated route for
/// [_i4.ExamDetailScreen]
class ExamDetailRoute extends _i21.PageRouteInfo<ExamDetailRouteArgs> {
  ExamDetailRoute({
    _i22.Key? key,
    required int examId,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         ExamDetailRoute.name,
         args: ExamDetailRouteArgs(key: key, examId: examId),
         initialChildren: children,
       );

  static const String name = 'ExamDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExamDetailRouteArgs>();
      return _i4.ExamDetailScreen(key: args.key, examId: args.examId);
    },
  );
}

class ExamDetailRouteArgs {
  const ExamDetailRouteArgs({this.key, required this.examId});

  final _i22.Key? key;

  final int examId;

  @override
  String toString() {
    return 'ExamDetailRouteArgs{key: $key, examId: $examId}';
  }
}

/// generated route for
/// [_i5.ExamFormScreen]
class ExamFormRoute extends _i21.PageRouteInfo<ExamFormRouteArgs> {
  ExamFormRoute({
    _i22.Key? key,
    int? examId,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         ExamFormRoute.name,
         args: ExamFormRouteArgs(key: key, examId: examId),
         initialChildren: children,
       );

  static const String name = 'ExamFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ExamFormRouteArgs>(
        orElse: () => const ExamFormRouteArgs(),
      );
      return _i5.ExamFormScreen(key: args.key, examId: args.examId);
    },
  );
}

class ExamFormRouteArgs {
  const ExamFormRouteArgs({this.key, this.examId});

  final _i22.Key? key;

  final int? examId;

  @override
  String toString() {
    return 'ExamFormRouteArgs{key: $key, examId: $examId}';
  }
}

/// generated route for
/// [_i6.ExamListScreen]
class ExamListRoute extends _i21.PageRouteInfo<void> {
  const ExamListRoute({List<_i21.PageRouteInfo>? children})
    : super(ExamListRoute.name, initialChildren: children);

  static const String name = 'ExamListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i6.ExamListScreen();
    },
  );
}

/// generated route for
/// [_i7.ExamsManagementScreen]
class ExamsManagementRoute extends _i21.PageRouteInfo<void> {
  const ExamsManagementRoute({List<_i21.PageRouteInfo>? children})
    : super(ExamsManagementRoute.name, initialChildren: children);

  static const String name = 'ExamsManagementRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i7.ExamsManagementScreen();
    },
  );
}

/// generated route for
/// [_i8.GroupFormScreen]
class GroupFormRoute extends _i21.PageRouteInfo<GroupFormRouteArgs> {
  GroupFormRoute({_i22.Key? key, int? id, List<_i21.PageRouteInfo>? children})
    : super(
        GroupFormRoute.name,
        args: GroupFormRouteArgs(key: key, id: id),
        initialChildren: children,
      );

  static const String name = 'GroupFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<GroupFormRouteArgs>(
        orElse: () => const GroupFormRouteArgs(),
      );
      return _i8.GroupFormScreen(key: args.key, id: args.id);
    },
  );
}

class GroupFormRouteArgs {
  const GroupFormRouteArgs({this.key, this.id});

  final _i22.Key? key;

  final int? id;

  @override
  String toString() {
    return 'GroupFormRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i9.GroupListScreen]
class GroupListRoute extends _i21.PageRouteInfo<void> {
  const GroupListRoute({List<_i21.PageRouteInfo>? children})
    : super(GroupListRoute.name, initialChildren: children);

  static const String name = 'GroupListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i9.GroupListScreen();
    },
  );
}

/// generated route for
/// [_i10.LoginScreen]
class LoginRoute extends _i21.PageRouteInfo<void> {
  const LoginRoute({List<_i21.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i10.LoginScreen();
    },
  );
}

/// generated route for
/// [_i11.MarkEntryScreen]
class MarkEntryRoute extends _i21.PageRouteInfo<MarkEntryRouteArgs> {
  MarkEntryRoute({_i22.Key? key, int? id, List<_i21.PageRouteInfo>? children})
    : super(
        MarkEntryRoute.name,
        args: MarkEntryRouteArgs(key: key, id: id),
        initialChildren: children,
      );

  static const String name = 'MarkEntryRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MarkEntryRouteArgs>(
        orElse: () => const MarkEntryRouteArgs(),
      );
      return _i11.MarkEntryScreen(key: args.key, id: args.id);
    },
  );
}

class MarkEntryRouteArgs {
  const MarkEntryRouteArgs({this.key, this.id});

  final _i22.Key? key;

  final int? id;

  @override
  String toString() {
    return 'MarkEntryRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i12.PaymentFormScreen]
class PaymentFormRoute extends _i21.PageRouteInfo<void> {
  const PaymentFormRoute({List<_i21.PageRouteInfo>? children})
    : super(PaymentFormRoute.name, initialChildren: children);

  static const String name = 'PaymentFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i12.PaymentFormScreen();
    },
  );
}

/// generated route for
/// [_i13.PaymentListScreen]
class PaymentListRoute extends _i21.PageRouteInfo<void> {
  const PaymentListRoute({List<_i21.PageRouteInfo>? children})
    : super(PaymentListRoute.name, initialChildren: children);

  static const String name = 'PaymentListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i13.PaymentListScreen();
    },
  );
}

/// generated route for
/// [_i14.QrScannerScreen]
class QrScannerRoute extends _i21.PageRouteInfo<void> {
  const QrScannerRoute({List<_i21.PageRouteInfo>? children})
    : super(QrScannerRoute.name, initialChildren: children);

  static const String name = 'QrScannerRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i14.QrScannerScreen();
    },
  );
}

/// generated route for
/// [_i15.ReportScreen]
class ReportRoute extends _i21.PageRouteInfo<void> {
  const ReportRoute({List<_i21.PageRouteInfo>? children})
    : super(ReportRoute.name, initialChildren: children);

  static const String name = 'ReportRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i15.ReportScreen();
    },
  );
}

/// generated route for
/// [_i16.ShellScreen]
class ShellRoute extends _i21.PageRouteInfo<void> {
  const ShellRoute({List<_i21.PageRouteInfo>? children})
    : super(ShellRoute.name, initialChildren: children);

  static const String name = 'ShellRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i16.ShellScreen();
    },
  );
}

/// generated route for
/// [_i17.StudentDetailScreen]
class StudentDetailRoute extends _i21.PageRouteInfo<StudentDetailRouteArgs> {
  StudentDetailRoute({
    _i22.Key? key,
    required int id,
    List<_i21.PageRouteInfo>? children,
  }) : super(
         StudentDetailRoute.name,
         args: StudentDetailRouteArgs(key: key, id: id),
         initialChildren: children,
       );

  static const String name = 'StudentDetailRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StudentDetailRouteArgs>();
      return _i17.StudentDetailScreen(key: args.key, id: args.id);
    },
  );
}

class StudentDetailRouteArgs {
  const StudentDetailRouteArgs({this.key, required this.id});

  final _i22.Key? key;

  final int id;

  @override
  String toString() {
    return 'StudentDetailRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i18.StudentFormScreen]
class StudentFormRoute extends _i21.PageRouteInfo<StudentFormRouteArgs> {
  StudentFormRoute({_i22.Key? key, int? id, List<_i21.PageRouteInfo>? children})
    : super(
        StudentFormRoute.name,
        args: StudentFormRouteArgs(key: key, id: id),
        initialChildren: children,
      );

  static const String name = 'StudentFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<StudentFormRouteArgs>(
        orElse: () => const StudentFormRouteArgs(),
      );
      return _i18.StudentFormScreen(key: args.key, id: args.id);
    },
  );
}

class StudentFormRouteArgs {
  const StudentFormRouteArgs({this.key, this.id});

  final _i22.Key? key;

  final int? id;

  @override
  String toString() {
    return 'StudentFormRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [_i19.StudentListScreen]
class StudentListRoute extends _i21.PageRouteInfo<void> {
  const StudentListRoute({List<_i21.PageRouteInfo>? children})
    : super(StudentListRoute.name, initialChildren: children);

  static const String name = 'StudentListRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      return const _i19.StudentListScreen();
    },
  );
}

/// generated route for
/// [_i20.UserFormScreen]
class UserFormRoute extends _i21.PageRouteInfo<UserFormRouteArgs> {
  UserFormRoute({_i22.Key? key, int? id, List<_i21.PageRouteInfo>? children})
    : super(
        UserFormRoute.name,
        args: UserFormRouteArgs(key: key, id: id),
        initialChildren: children,
      );

  static const String name = 'UserFormRoute';

  static _i21.PageInfo page = _i21.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserFormRouteArgs>(
        orElse: () => const UserFormRouteArgs(),
      );
      return _i20.UserFormScreen(key: args.key, id: args.id);
    },
  );
}

class UserFormRouteArgs {
  const UserFormRouteArgs({this.key, this.id});

  final _i22.Key? key;

  final int? id;

  @override
  String toString() {
    return 'UserFormRouteArgs{key: $key, id: $id}';
  }
}

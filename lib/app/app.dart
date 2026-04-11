import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'cubits/locale_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'router/app_router.gr.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import '../features/auth/cubits/auth_cubit.dart';
import '../features/admin/cubits/admin_cubit.dart';
import '../features/dashboard/cubits/dashboard_cubit.dart';
import '../features/students/cubits/student_cubit.dart';
import '../features/groups/cubits/group_cubit.dart';
import '../features/payments/cubits/payment_cubit.dart';
import '../features/attendance/cubits/attendance_cubit.dart';
import '../features/exams/cubits/exam_cubit.dart';
import '../features/reports/cubits/report_cubit.dart';
import '../features/assistants/cubits/assistant_cubit.dart';
import '../features/assistants/cubits/assistant_attendance_cubit.dart';
import '../features/notes/cubits/notes_cubit.dart';

class StudentsManagementApp extends StatefulWidget {
  const StudentsManagementApp({super.key});

  @override
  State<StudentsManagementApp> createState() => _StudentsManagementAppState();
}

class _StudentsManagementAppState extends State<StudentsManagementApp> {
  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    final dbService = getIt<DatabaseService>();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => AuthCubit(databaseService: dbService)),
        BlocProvider(create: (_) => AdminCubit(databaseService: dbService)),
        BlocProvider(create: (_) => DashboardCubit(databaseService: dbService)),
        BlocProvider(create: (_) => StudentCubit(databaseService: dbService)),
        BlocProvider(create: (_) => GroupCubit(databaseService: dbService)),
        BlocProvider(create: (_) => PaymentCubit(databaseService: dbService)),
        BlocProvider(create: (_) => AttendanceCubit(databaseService: dbService)),
        BlocProvider(create: (_) => ExamCubit(databaseService: dbService)),
        BlocProvider(create: (_) => ReportCubit(databaseService: dbService)),
        BlocProvider(create: (_) => AssistantCubit(databaseService: dbService)),
        BlocProvider(create: (_) => AssistantAttendanceCubit(databaseService: dbService)),
        BlocProvider(create: (_) => NotesCubit(databaseService: dbService)),
      ],
      child: BlocBuilder<LocaleCubit, LocaleState>(
        builder: (context, localeState) {
          return ScreenUtilInit(
            designSize: const Size(390, 844),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  state.maybeWhen(
                    authenticated: (_) => _appRouter.replaceAll([const ShellRoute()]),
                    initial: () => _appRouter.replaceAll([const LoginRoute()]),
                    orElse: () {},
                  );
                },
                child: MaterialApp.router(
                  title: 'Student Management System',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode:
                      localeState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  routerConfig: _appRouter.config(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

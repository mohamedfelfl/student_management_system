import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../generated/locale_keys.g.dart';

import '../../../../app/router/app_router.gr.dart';
import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../auth/cubits/auth_cubit.dart';
import '../../../auth/models/user.dart';
import '../../cubits/dashboard_cubit.dart';
import 'components/banner_stat.dart';
import 'components/action_card.dart';

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final User? user = context.read<AuthCubit>().state.maybeWhen(
      authenticated: (u) => u,
      orElse: () => null,
    );

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (BuildContext context, DashboardState state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              LocaleKeys.app_title.tr(),
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            leading: ResponsiveLayout.isMobile(context)
                ? IconButton(
                    icon: Icon(Icons.menu, color: colorScheme.onSurface),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.language),
                onPressed: () {
                  if (context.locale.languageCode == 'en') {
                    context.setLocale(const Locale('ar'));
                  } else {
                    context.setLocale(const Locale('en'));
                  }
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Banner
                  Container(
                    padding: EdgeInsets.all(28.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHigh
                          : colorScheme.primary,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 24.r,
                          offset: Offset(0, 8.h),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.welcome_admin.tr()
                              .replaceAll('المسؤول', user?.username ?? 'Admin')
                              .replaceAll('Admin', user?.username ?? 'Admin'),
                          style: textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          LocaleKeys.center_overview.tr(),
                          style: textTheme.headlineMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            BannerStat(
                              label: LocaleKeys.total_students.tr(),
                              value: '${state.totalStudents}',
                              isDark: isDark,
                            ),
                            Container(
                              width: 1.w,
                              height: 40.h,
                              color: isDark
                                  ? colorScheme.outlineVariant.withValues(
                                      alpha: 0.3,
                                    )
                                  : colorScheme.onPrimary.withValues(
                                      alpha: 0.2,
                                    ),
                            ),
                            BannerStat(
                              label: LocaleKeys.active_groups.tr(),
                              value: '${state.totalGroups}',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Quick Actions Grid
                  Text(LocaleKeys.quick_actions.tr(), style: textTheme.titleLarge),
                  SizedBox(height: 16.h),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final int crossAxisCount = constraints.maxWidth > 800
                              ? 6
                              : 3;

                          final actions = [
                            if (user?.can(UserPermission.manageStudents) ?? false)
                              ActionCard(
                                icon: Icons.person_add_rounded,
                                label: LocaleKeys.new_student.tr(),
                                onTap: () => context.router.push(StudentFormRoute()),
                                color: const Color(0xFF6750A4),
                              ),
                            if (user?.can(UserPermission.manageAttendance) ?? false)
                              ActionCard(
                                icon: Icons.qr_code_scanner_rounded,
                                label: LocaleKeys.scan_qr.tr(),
                                onTap: () => context.router.push(QrScannerRoute()),
                                color: const Color(0xFFE91E63),
                              ),
                            if (user?.can(UserPermission.managePayments) ?? false)
                              ActionCard(
                                icon: Icons.payments_rounded,
                                label: LocaleKeys.add_payment.tr(),
                                onTap: () => context.router.push(PaymentListRoute()),
                                color: const Color(0xFF4CAF50),
                              ),
                            if (user?.can(UserPermission.manageExams) ?? false)
                              ActionCard(
                                icon: Icons.quiz_rounded,
                                label: LocaleKeys.exams.tr(),
                                onTap: () => context.router.push(ExamFormRoute()),
                                color: const Color(0xFFFF9800),
                              ),
                            if (user?.can(UserPermission.viewReports) ?? false)
                              ActionCard(
                                icon: Icons.analytics_rounded,
                                label: LocaleKeys.reports.tr(),
                                onTap: () => context.router.push(ReportRoute()),
                                color: const Color(0xFF2196F3),
                              ),
                            if (user?.can(UserPermission.manageGroups) ?? false)
                              ActionCard(
                                icon: Icons.groups_rounded,
                                label: LocaleKeys.groups.tr(),
                                onTap: () => context.router.push(GroupListRoute()),
                                color: const Color(0xFF9C27B0),
                              ),
                            if (user?.can(UserPermission.manageNotes) ?? false)
                              ActionCard(
                                icon: Icons.menu_book_rounded,
                                label: LocaleKeys.notes.tr(),
                                onTap: () => context.router.push(NotesRoute()),
                                color: const Color(0xFF00897B),
                              ),
                          ];

                          return GridView.count(
                            crossAxisCount: crossAxisCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16.r,
                            crossAxisSpacing: 16.r,
                            childAspectRatio: 0.85,
                            children: actions,
                          );
                        },
                  ),
                  SizedBox(height: 32.h),


                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

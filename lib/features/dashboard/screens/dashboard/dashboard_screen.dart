import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/router/app_router.gr.dart';
import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../auth/cubits/auth_cubit.dart';
import '../../../auth/models/user.dart';
import '../../cubits/dashboard_cubit.dart';
import 'components/action_card.dart';
import 'components/banner_stat.dart';

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

  void _navigateAndRefresh(PageRouteInfo route) {
    context.router.push(route).then((_) {
      if (mounted) {
        context.read<DashboardCubit>().loadDashboard();
      }
    });
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
            leading: context.router.canPop()
                ? const BackButton()
                : ResponsiveLayout.isMobile(context)
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          LocaleKeys.welcome_admin
                              .tr()
                              .replaceAll('المسؤول', user?.username ?? 'Admin')
                              .replaceAll('Admin', user?.username ?? 'Admin'),
                          textAlign: TextAlign.start,
                          style: textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          LocaleKeys.center_overview.tr(),
                          textAlign: TextAlign.start,
                          style: textTheme.headlineMedium?.copyWith(
                            color: isDark
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BannerStat(
                                label: LocaleKeys.total_students.tr(),
                                value: '${state.totalStudents}',
                                isDark: isDark,
                              ),
                              _buildSeparator(colorScheme, isDark),
                              BannerStat(
                                label: LocaleKeys.active_groups.tr(),
                                value: '${state.totalGroups}',
                                isDark: isDark,
                              ),
                              _buildSeparator(colorScheme, isDark),
                              BannerStat(
                                label: LocaleKeys.total_assistants.tr(),
                                value: '${state.totalAssistants}',
                                isDark: isDark,
                              ),
                              _buildSeparator(colorScheme, isDark),
                              BannerStat(
                                label: LocaleKeys.total_exams.tr(),
                                value: '${state.totalExams}',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Quick Actions Grid
                  Text(
                    LocaleKeys.quick_actions.tr(),
                    style: textTheme.titleLarge,
                  ),
                  SizedBox(height: 16.h),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final int crossAxisCount = constraints.maxWidth > 800
                              ? 6
                              : 3;

                          final actions = [
                            if (user?.can(UserPermission.manageStudents) ??
                                false)
                              ActionCard(
                                icon: Icons.person_add_rounded,
                                label: LocaleKeys.new_student.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(StudentFormRoute()),
                                color: const Color(0xFF6750A4),
                              ),
                            if (user?.can(UserPermission.manageAttendance) ??
                                false)
                              ActionCard(
                                icon: Icons.qr_code_scanner_rounded,
                                label: LocaleKeys.scan_qr.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(QrScannerRoute()),
                                color: const Color(0xFFE91E63),
                              ),
                            if (user?.can(UserPermission.managePayments) ??
                                false)
                              ActionCard(
                                icon: Icons.payments_rounded,
                                label: LocaleKeys.add_payment.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(PaymentListRoute()),
                                color: const Color(0xFF4CAF50),
                              ),
                            if (user?.can(UserPermission.manageExams) ?? false)
                              ActionCard(
                                icon: Icons.quiz_rounded,
                                label: LocaleKeys.exams.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(ExamFormRoute()),
                                color: const Color(0xFFFF9800),
                              ),
                            if (user?.can(UserPermission.viewReports) ?? false)
                              ActionCard(
                                icon: Icons.analytics_rounded,
                                label: LocaleKeys.reports.tr(),
                                onTap: () => _navigateAndRefresh(ReportRoute()),
                                color: const Color(0xFF2196F3),
                              ),
                            if (user?.can(UserPermission.manageGroups) ?? false)
                              ActionCard(
                                icon: Icons.groups_rounded,
                                label: LocaleKeys.groups.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(GroupListRoute()),
                                color: const Color(0xFF9C27B0),
                              ),
                            if (user?.can(UserPermission.manageNotes) ?? false)
                              ActionCard(
                                icon: Icons.menu_book_rounded,
                                label: LocaleKeys.notes.tr(),
                                onTap: () => _navigateAndRefresh(NotesRoute()),
                                color: const Color(0xFF00897B),
                              ),
                            if (user?.can(UserPermission.manageAssistants) ??
                                false)
                              ActionCard(
                                icon: Icons.support_agent_rounded,
                                label: LocaleKeys.assistants_directory.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(const AssistantListRoute()),
                                color: const Color(0xFF795548),
                              ),
                            if (user?.role == UserRole.admin ||
                                (user?.can(UserPermission.manageUsers) ??
                                    false))
                              ActionCard(
                                icon: Icons.admin_panel_settings_rounded,
                                label: LocaleKeys.admin_panel.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(const AdminPanelRoute()),
                                color: const Color(0xFF3F51B5),
                              ),
                            if (user?.can(UserPermission.viewReports) ?? false)
                              ActionCard(
                                icon: Icons.emoji_events_rounded,
                                label: LocaleKeys.honor_board.tr(),
                                onTap: () =>
                                    _navigateAndRefresh(const HonoredStudentsRoute()),
                                color: const Color(0xFFFFC107),
                              ),
                            ActionCard(
                              icon: Icons.settings_rounded,
                              label: LocaleKeys.settings.tr(),
                              onTap: () =>
                                  _navigateAndRefresh(const SettingsRoute()),
                              color: const Color(0xFF607D8B),
                            ),
                            ActionCard(
                              icon: Icons.logout_rounded,
                              label: LocaleKeys.logout.tr(),
                              onTap: () => context.read<AuthCubit>().logout(),
                              color: colorScheme.error,
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

  Widget _buildSeparator(ColorScheme colorScheme, bool isDark) {
    return Container(
      height: 32.h,
      width: 1.5,
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: (isDark ? colorScheme.onSurface : colorScheme.onPrimary)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

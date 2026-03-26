import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../generated/locale_keys.g.dart';

import '../../../app/router/app_router.gr.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../../../app/shared/screens/shell_screen.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user.dart';
import '../cubits/dashboard_cubit.dart';

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

    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (BuildContext context, DashboardState state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.app_title.tr(),
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8.w),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=11',
                  ),
                ),
              ],
            ),
            centerTitle: true,
            leading: ResponsiveLayout.isMobile(context)
                ? IconButton(
                    icon: Icon(Icons.menu, color: colorScheme.onSurface),
                    onPressed: () => ShellScreen.scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
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
                          LocaleKeys.welcome_admin.tr(),
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
                            _BannerStat(
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
                            _BannerStat(
                              label: LocaleKeys.active_groups.tr(),
                              value: '${state.totalGroups}',
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
                            _BannerStat(
                              label: LocaleKeys.attendance_rate.tr(),
                              value:
                                  '${state.attendanceRate.toStringAsFixed(0)}%',
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Quick Actions Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(LocaleKeys.quick_actions.tr(), style: textTheme.titleLarge),
                      Icon(Icons.tune, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final int crossAxisCount = constraints.maxWidth > 800
                              ? 6
                              : 3;
                          final User? user = context.read<AuthCubit>().state.maybeWhen(
                            authenticated: (u) => u,
                            orElse: () => null,
                          );

                          final actions = [
                            if (user?.can(UserPermission.manageStudents) ?? false)
                              _ActionCard(
                                icon: Icons.person_add_rounded,
                                label: LocaleKeys.new_student.tr(),
                                onTap: () => context.router.push(StudentFormRoute()),
                                color: const Color(0xFF6750A4),
                              ),
                            if (user?.can(UserPermission.manageAttendance) ?? false)
                              _ActionCard(
                                icon: Icons.qr_code_scanner_rounded,
                                label: LocaleKeys.scan_qr.tr(),
                                onTap: () => context.router.push(QrScannerRoute()),
                                color: const Color(0xFFE91E63),
                              ),
                            if (user?.can(UserPermission.managePayments) ?? false)
                              _ActionCard(
                                icon: Icons.payments_rounded,
                                label: LocaleKeys.add_payment.tr(),
                                onTap: () => context.router.push(PaymentListRoute()),
                                color: const Color(0xFF4CAF50),
                              ),
                            if (user?.can(UserPermission.manageExams) ?? false)
                              _ActionCard(
                                icon: Icons.quiz_rounded,
                                label: LocaleKeys.exams.tr(),
                                onTap: () => context.router.push(ExamFormRoute()),
                                color: const Color(0xFFFF9800),
                              ),
                            if (user?.can(UserPermission.viewReports) ?? false)
                              _ActionCard(
                                icon: Icons.analytics_rounded,
                                label: LocaleKeys.reports.tr(),
                                onTap: () => context.router.push(ReportRoute()),
                                color: const Color(0xFF2196F3),
                              ),
                            if (user?.can(UserPermission.manageGroups) ?? false)
                              _ActionCard(
                                icon: Icons.groups_rounded,
                                label: LocaleKeys.groups.tr(),
                                onTap: () => context.router.push(GroupListRoute()),
                                color: const Color(0xFF9C27B0),
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

                  // Recent Activity
                  if (state.recentAttendance.isNotEmpty) ...[
                    Text(LocaleKeys.recent_attendance.tr(), style: textTheme.titleLarge),
                    SizedBox(height: 16.h),
                    ...state.recentAttendance.map(
                      (Map<String, Object?> a) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ActivityCard(
                          status: a['status'] as String,
                          name: a['student_name']?.toString() ?? 'Unknown',
                          date: a['date']?.toString() ?? '',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                        ),
                      ),
                    ),
                  ],
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

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _BannerStat({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            color: isDark ? colorScheme.onSurface : colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isDark
                ? colorScheme.onSurfaceVariant
                : colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.1),
                  blurRadius: 12.r,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String status;
  final String name;
  final String date;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ActivityCard({
    required this.status,
    required this.name,
    required this.date,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'attended':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'missed':
        statusColor = const Color(0xFFE91E63);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = const Color(0xFFFF9800);
        statusIcon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.outlineVariant.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colorScheme.outlineVariant),
        ],
      ),
    );
  }
}

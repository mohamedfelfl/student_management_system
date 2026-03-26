import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/locale_cubit.dart';
import '../../../features/auth/cubits/auth_cubit.dart';
import '../../../features/auth/models/user.dart';
import '../../router/app_router.gr.dart';
import '../widgets/responsive_layout.dart';
import '../../../generated/locale_keys.g.dart';

@RoutePage(name: 'ShellRoute')
class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key});

  /// Global key to access the shell's [ScaffoldState] from child screens.
  static final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final User? user = authState.maybeWhen(
          authenticated: (u) => u,
          orElse: () => null,
        );

        if (user == null) return const Scaffold();

        final List<({PageRouteInfo route, NavigationRailDestination destination})> menuItems = [
          (
            route: const DashboardRoute(),
            destination: NavigationRailDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard),
              label: Text('dashboard'.tr()),
            ),
          ),
          if (user.can(UserPermission.manageStudents))
            (
              route: const StudentListRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.people_outline),
                selectedIcon: const Icon(Icons.people),
                label: Text('students'.tr()),
              ),
            ),
          if (user.can(UserPermission.manageExams))
            (
              route: const ExamListRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.quiz_outlined),
                selectedIcon: const Icon(Icons.quiz),
                label: Text('exams'.tr()),
              ),
            ),
          if (user.can(UserPermission.managePayments))
            (
              route: const PaymentListRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.payment_outlined),
                selectedIcon: const Icon(Icons.payment),
                label: Text('payments_tracking'.tr()),
              ),
            ),
          if (user.can(UserPermission.manageAttendance))
            (
              route: const QrScannerRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: const Icon(Icons.qr_code_scanner),
                label: Text(LocaleKeys.qr_attendance.tr()),
              ),
            ),
          if (user.can(UserPermission.manageGroups))
            (
              route: const GroupListRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.groups_outlined),
                selectedIcon: const Icon(Icons.groups),
                label: Text('groups'.tr()),
              ),
            ),
          if (user.can(UserPermission.viewReports))
            (
              route: const ReportRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.assessment_outlined),
                selectedIcon: const Icon(Icons.assessment),
                label: Text('reports'.tr()),
              ),
            ),
          if (user.role == UserRole.admin || user.can(UserPermission.manageUsers))
            (
              route: const AdminPanelRoute(),
              destination: NavigationRailDestination(
                icon: const Icon(Icons.admin_panel_settings_outlined),
                selectedIcon: const Icon(Icons.admin_panel_settings),
                label: Text('admin'.tr()),
              ),
            ),
        ];

        final List<PageRouteInfo> filteredRoutes = menuItems.map((e) => e.route).toList();
        final List<NavigationRailDestination> destinations = menuItems.map((e) => e.destination).toList();

        return AutoTabsRouter(
          routes: filteredRoutes,
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            
            return Scaffold(
              key: ShellScreen.scaffoldKey,
              drawer: ResponsiveLayout.isMobile(context)
                  ? _buildDrawer(context, isDark, colorScheme, destinations, tabsRouter)
                  : null,
              body: ResponsiveLayout(
                selectedIndex: tabsRouter.activeIndex,
                onDestinationSelected: tabsRouter.setActiveIndex,
                destinations: destinations,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.school, color: colorScheme.primary, size: 32),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => context.read<AuthCubit>().logout(),
                        tooltip: 'logout'.tr(),
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ),
                mobileBody: child,
                desktopBody: child,
              ),
              bottomNavigationBar: ResponsiveLayout.isMobile(context)
                  ? NavigationBar(
                      selectedIndex: tabsRouter.activeIndex < destinations.length ? tabsRouter.activeIndex : 0,
                      onDestinationSelected: tabsRouter.setActiveIndex,
                      destinations: [
                        ...destinations
                            .take(5)
                            .map((d) => NavigationDestination(
                                  icon: d.icon,
                                  selectedIcon: d.selectedIcon,
                                  label: (d.label as Text).data ?? '',
                                )),
                        NavigationDestination(
                          icon: const Icon(Icons.logout),
                          label: 'logout'.tr(),
                        ),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
    List<NavigationRailDestination> destinations,
    TabsRouter tabsRouter,
  ) {
    return Drawer(
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.school, color: colorScheme.onPrimary, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'SMS',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(color: colorScheme.onPrimary),
                    ),
                  ],
                ),
              ),
              ...List.generate(destinations.length, (int i) {
                final NavigationRailDestination dest = destinations[i];
                final bool isSelected = tabsRouter.activeIndex == i;
                return ListTile(
                  leading: IconTheme(
                    data: IconThemeData(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    child: isSelected ? dest.selectedIcon : dest.icon,
                  ),
                  title: Text(
                    dest.label is Text ? (dest.label as Text).data ?? '' : '',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    tabsRouter.setActiveIndex(i);
                  },
                );
              }),
              const SizedBox(height: 16),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  'logout'.tr(),
                  style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  context.read<AuthCubit>().logout();
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.language, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () =>
                          context.read<LocaleCubit>().toggleLanguage(),
                      child: const Text('عربي / EN'),
                    ),
                    const Spacer(),
                    Icon(Icons.dark_mode, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Switch(
                      value: isDark,
                      onChanged: (_) =>
                          context.read<LocaleCubit>().toggleDarkMode(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

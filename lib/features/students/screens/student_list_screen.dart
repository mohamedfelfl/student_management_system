import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/router/app_router.gr.dart';
import '../../../app/shared/screens/shell_screen.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../../../generated/locale_keys.g.dart';
import '../cubits/student_cubit.dart';

@RoutePage()
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<StudentCubit>().loadStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.students_directory.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    ShellScreen.scaffoldKey.currentState?.openDrawer(),
              )
            : null,
      ),
      body: BlocBuilder<StudentCubit, StudentState>(
        builder: (BuildContext context, StudentState state) {
          final bool isSearching = state.searchQuery.isNotEmpty;
          final int filteredCount = state.students.length;
          final int totalStudents = state.totalCount;
          final bool hasSelection = state.selectedIds.isNotEmpty;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Banner: shows totalCount (stable) ──
                Container(
                  padding: EdgeInsets.all(28.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHigh
                        : colorScheme.primary,
                    borderRadius: BorderRadius.circular(28.r),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 24.r,
                          offset: Offset(0, 8.h),
                        ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Icon(
                          Icons.groups,
                          size: 100.r,
                          color: colorScheme.onPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LocaleKeys.total_enrolled.tr(),
                            style: textTheme.titleLarge?.copyWith(
                              color: isDark
                                  ? colorScheme.onSurfaceVariant
                                  : colorScheme.onPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Text(
                                '$totalStudents',
                                style: textTheme.displayMedium?.copyWith(
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // ── Search & Actions ──
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (String q) =>
                            context.read<StudentCubit>().search(q),
                        decoration: InputDecoration(
                          hintText: LocaleKeys.search_hint.tr(),
                          prefixIcon: const Icon(Icons.search),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Bulk delete button (visible when items are selected)
                    if (hasSelection) ...[
                      ElevatedButton.icon(
                        onPressed: () => _confirmBulkDelete(state.selectedIds),
                        icon: const Icon(Icons.delete_sweep),
                        label: Text(
                          '${LocaleKeys.delete_selected.tr()} (${state.selectedIds.length})',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 24.h,
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                    ],
                    ElevatedButton.icon(
                      onPressed: () => context.router.push(StudentFormRoute()),
                      icon: const Icon(Icons.person_add),
                      label: Text(LocaleKeys.add_new.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 24.h,
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Search results indicator (Polished) ──
                if (isSearching && !state.isLoading) ...[
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: colorScheme.secondary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 16.r,
                            color: colorScheme.onSecondaryContainer,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            LocaleKeys.search_results_found.tr(),
                            style: textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '$filteredCount',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 30.h),

                // ── Data Table ──
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.students.isEmpty
                      ? _buildEmptyState(context)
                      : Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? colorScheme.surfaceContainerLow
                                : colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(28.r),
                            boxShadow: [
                              if (!isDark)
                                BoxShadow(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.1,
                                  ),
                                  blurRadius: 16.r,
                                  offset: Offset(0, 4.h),
                                ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Material(
                            type: MaterialType.transparency,
                            child: DataTable2(
                              dataRowColor:
                                  WidgetStateProperty.resolveWith<Color?>((
                                    Set<WidgetState> states,
                                  ) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return colorScheme.primary.withValues(
                                        alpha: 0.08,
                                      );
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return colorScheme.primary.withValues(
                                        alpha: 0.04,
                                      );
                                    }
                                    return null;
                                  }),
                              columnSpacing: 18.w,
                              horizontalMargin: 20.w,
                              minWidth: 700.w,
                              dataRowHeight: 90.h,
                              dividerThickness: 0,
                              headingRowDecoration: BoxDecoration(
                                color: isDark
                                    ? colorScheme.surfaceContainer
                                    : colorScheme.surfaceContainerLow,
                              ),
                              columns: [
                                // Checkbox header (select all)
                                DataColumn2(
                                  label: Checkbox(
                                    value:
                                        state.students.isNotEmpty &&
                                        state.selectedIds.length ==
                                            state.students.length,
                                    tristate: true,
                                    onChanged: (_) => context
                                        .read<StudentCubit>()
                                        .toggleAll(),
                                  ),
                                  fixedWidth: 50,
                                ),
                                DataColumn2(
                                  label: Text(
                                    LocaleKeys.id_serial.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  size: ColumnSize.S,
                                ),
                                DataColumn2(
                                  label: Text(
                                    LocaleKeys.name.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  size: ColumnSize.L,
                                ),
                                DataColumn2(
                                  label: Text(
                                    LocaleKeys.school_group.tr(),
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  size: ColumnSize.M,
                                ),
                                // Actions column
                                const DataColumn2(
                                  label: Text(''),
                                  fixedWidth: 120,
                                ),
                              ],
                              rows: state.students.map((s) {
                                final int id = s['id'] as int;
                                final bool isSelected = state.selectedIds
                                    .contains(id);

                                return DataRow2(
                                  selected: isSelected,
                                  onTap: () => context.router.push(
                                    StudentDetailRoute(id: id),
                                  ),
                                  cells: [
                                    // Checkbox cell
                                    DataCell(
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (_) => context
                                            .read<StudentCubit>()
                                            .toggleSelection(id),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        s['serial_number']?.toString() ?? '',
                                        style: textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12.h,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              s['name']?.toString() ?? '',
                                              style: textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              s['phone1']?.toString() ?? '',
                                              style: textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              s['school']?.toString() ??
                                                  LocaleKeys.na.tr(),
                                              style: textTheme.bodyLarge
                                                  ?.copyWith(fontSize: 16.sp),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 8.h),
                                            Text(
                                              s['group_name']?.toString() ??
                                                  LocaleKeys.unassigned.tr(),
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Actions cell: edit + delete icons
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              size: 20,
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                            tooltip: LocaleKeys.edit.tr(),
                                            onPressed: () => context.router
                                                .push(StudentFormRoute(id: id)),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: colorScheme.error,
                                            ),
                                            tooltip: LocaleKeys.delete.tr(),
                                            onPressed: () => _confirmDelete(s),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(LocaleKeys.no_students_found.tr(), style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.adjust_filters_hint.tr(),
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, Object?> student) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(LocaleKeys.delete_student.tr()),
        content: Text(
          LocaleKeys.confirm_delete_student.tr(
            args: [student['name'].toString()],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StudentCubit>().deleteStudent(student['id'] as int);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(Set<int> ids) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: Text(LocaleKeys.delete_student.tr()),
        content: Text(
          LocaleKeys.confirm_bulk_delete.tr(args: ['${ids.length}']),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StudentCubit>().deleteMultipleStudents(ids);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }
}

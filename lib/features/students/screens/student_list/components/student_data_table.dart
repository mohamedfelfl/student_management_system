import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:student_management_system/app/router/app_router.gr.dart';
import 'package:student_management_system/generated/locale_keys.g.dart';

class StudentDataTable extends StatelessWidget {
  final List<Map<String, Object?>> students;
  final Set<int> selectedIds;
  final VoidCallback onToggleAll;
  final ValueChanged<int> onToggleSelection;
  final ValueChanged<Map<String, Object?>> onDeleteStudent;

  const StudentDataTable({
    super.key,
    required this.students,
    required this.selectedIds,
    required this.onToggleAll,
    required this.onToggleSelection,
    required this.onDeleteStudent,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: colorScheme.outlineVariant.withValues(alpha: 0.1),
              blurRadius: 16.r,
              offset: Offset(0, 4.h),
            ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: DataTable2(
          dataRowColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withValues(alpha: 0.08);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withValues(alpha: 0.04);
            }
            return null;
          }),
          columnSpacing: 18.w,
          horizontalMargin: 20.w,
          minWidth: 700.w,
          dataRowHeight: 120.h,
          dividerThickness: 0,
          headingRowDecoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainer
                : colorScheme.surfaceContainerLow,
          ),
          columns: [
            DataColumn2(
              label: Checkbox(
                value:
                    students.isNotEmpty &&
                    selectedIds.length == students.length,
                tristate: true,
                onChanged: (_) => onToggleAll(),
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
            const DataColumn2(label: Text(''), fixedWidth: 120),
          ],
          rows: students.map((s) {
            final int id = s['id'] as int;
            final bool isSelected = selectedIds.contains(id);

            return DataRow2(
              selected: isSelected,
              onTap: () => context.router.push(StudentDetailRoute(id: id)),
              cells: [
                DataCell(
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelection(id),
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
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name']?.toString() ?? '',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s['phone1']?.toString() ?? '',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${s['school']?.toString() ?? LocaleKeys.na.tr()} (${_getGradeLabel(s['grade']?.toString())})',
                          style: textTheme.bodyLarge?.copyWith(fontSize: 16.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          s['group_name']?.toString() ??
                              LocaleKeys.unassigned.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: LocaleKeys.edit.tr(),
                        onPressed: () =>
                            context.router.push(StudentFormRoute(id: id)),
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
                        onPressed: () => onDeleteStudent(s),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  String _getGradeLabel(String? grade) {
    if (grade == 'primary_1') return LocaleKeys.primary_1.tr();
    if (grade == 'primary_2') return LocaleKeys.primary_2.tr();
    if (grade == 'primary_3') return LocaleKeys.primary_3.tr();
    if (grade == 'primary_4') return LocaleKeys.primary_4.tr();
    if (grade == 'primary_5') return LocaleKeys.primary_5.tr();
    if (grade == 'primary_6') return LocaleKeys.primary_6.tr();
    if (grade == 'prep_1') return LocaleKeys.prep_1.tr();
    if (grade == 'prep_2') return LocaleKeys.prep_2.tr();
    if (grade == 'prep_3') return LocaleKeys.prep_3.tr();
    if (grade == 'sec_1') return LocaleKeys.sec_1.tr();
    if (grade == 'sec_2') return LocaleKeys.sec_2.tr();
    if (grade == 'sec_3') return LocaleKeys.sec_3.tr();
    return LocaleKeys.na.tr();
  }
}

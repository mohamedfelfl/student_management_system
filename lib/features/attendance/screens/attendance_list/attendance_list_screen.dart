import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../generated/locale_keys.g.dart';
import '../../cubits/attendance_cubit.dart';

@RoutePage()
class AttendanceListScreen extends StatefulWidget {
  final int? studentId;

  const AttendanceListScreen({
    super.key,
    @QueryParam('studentId') this.studentId,
  });

  @override
  State<AttendanceListScreen> createState() => _AttendanceListScreenState();
}

class _AttendanceListScreenState extends State<AttendanceListScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.studentId != null) {
        context.read<AttendanceCubit>().loadAttendance(widget.studentId!);
      } else {
        context.read<AttendanceCubit>().loadAllAttendance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'attendance_records'.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedDate == null
                  ? Icons.calendar_today
                  : Icons.calendar_today_outlined,
              color: _selectedDate == null ? null : colorScheme.primary,
            ),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _selectedDate = null),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Filtering by: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (BuildContext context, AttendanceState state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final filteredRecords = _selectedDate == null
                      ? state.records
                      : state.records
                            .where(
                              (r) =>
                                  r['date'] ==
                                  DateFormat(
                                    'yyyy-MM-dd',
                                  ).format(_selectedDate!),
                            )
                            .toList();

                  if (filteredRecords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 64.r,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            LocaleKeys.no_attendance_records.tr(),
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  }
                  return Card(
                    child: ListView.builder(
                      padding: EdgeInsets.all(16.r),
                      itemCount: filteredRecords.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Map<String, Object?> a = filteredRecords[i];
                        final String status =
                            a['status']?.toString() ?? 'attended';
                        final int attendanceId = a['id'] as int;
                        final String notes = a['notes']?.toString() ?? '';

                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              // Status indicator with icon
                              Container(
                                width: 40.r,
                                height: 40.r,
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  status == 'attended'
                                      ? Icons.check_circle_outline
                                      : status == 'missed'
                                      ? Icons.cancel_outlined
                                      : Icons.swap_horiz_rounded,
                                  color: _statusColor(status),
                                  size: 22.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (a['student_name'] != null) ...[
                                      Text(
                                        a['student_name'].toString(),
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                    ],
                                    Text(
                                      a['date']?.toString() ?? '',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      SizedBox(height: 6.h),
                                      // Attendance type badge - prominent display
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'attended'
                                              ? Colors.green.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.orange.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                          border: Border.all(
                                            color: status == 'attended'
                                                ? Colors.green.withValues(
                                                    alpha: 0.3,
                                                  )
                                                : Colors.orange.withValues(
                                                    alpha: 0.3,
                                                  ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              status == 'attended'
                                                  ? Icons.groups_outlined
                                                  : Icons.swap_horiz_rounded,
                                              size: 14.r,
                                              color: status == 'attended'
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                            SizedBox(width: 4.w),
                                            Flexible(
                                              child: Text(
                                                notes,
                                                style: textTheme.labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          status == 'attended'
                                                          ? Colors
                                                                .green
                                                                .shade700
                                                          : Colors
                                                                .orange
                                                                .shade700,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 8.sp,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(_statusLabel(status)),
                                backgroundColor: _statusColor(
                                  status,
                                ).withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 7.sp,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _confirmDelete(context, attendanceId),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Attendance?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    context.read<AttendanceCubit>().deleteAttendance(
      id,
      studentId: widget.studentId,
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'attended':
        return Colors.green;
      case 'missed':
        return Colors.red;
      case 'otherLesson':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'attended':
        return LocaleKeys.present.tr();
      case 'missed':
        return LocaleKeys.absent.tr();
      case 'otherLesson':
        return LocaleKeys.other_lesson.tr();
      default:
        return status;
    }
  }
}

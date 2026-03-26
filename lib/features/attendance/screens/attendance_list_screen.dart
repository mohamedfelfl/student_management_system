import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../app/shared/screens/shell_screen.dart';
import '../cubits/attendance_cubit.dart';

@RoutePage()
class AttendanceListScreen extends StatelessWidget {
  final int? studentId;

  const AttendanceListScreen({
    super.key,
    @QueryParam('studentId') this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    if (studentId != null) {
      context.read<AttendanceCubit>().loadAttendance(studentId!);
    }

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
          icon: const Icon(Icons.menu),
          onPressed: () => ShellScreen.scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<AttendanceCubit, AttendanceState>(
                builder: (BuildContext context, AttendanceState state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.records.isEmpty) {
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
                      itemCount: state.records.length,
                      itemBuilder: (BuildContext context, int i) {
                        final Map<String, Object?> a = state.records[i];
                        final String status =
                            a['status']?.toString() ?? 'attended';
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            children: [
                              _statusIcon(status),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a['date']?.toString() ?? '',
                                      style: textTheme.bodyLarge,
                                    ),
                                    if ((a['notes']?.toString() ?? '')
                                        .isNotEmpty)
                                      Text(
                                        a['notes'].toString(),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
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
                                  fontSize: 12.sp,
                                ),
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

  Widget _statusIcon(String status) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _statusColor(status),
      ),
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

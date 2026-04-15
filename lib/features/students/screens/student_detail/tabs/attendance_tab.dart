import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../attendance/cubits/attendance_cubit.dart';

class AttendanceTab extends StatelessWidget {
  final int studentId;
  const AttendanceTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AttendanceCubit, AttendanceState>(
      builder: (context, state) {
        if (state.isLoading)
          return const Center(child: CircularProgressIndicator());
        if (state.records.isEmpty) {
          return Center(child: Text(LocaleKeys.no_attendance_records.tr()));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: state.records.length,
          itemBuilder: (context, i) {
            final a = state.records[i];
            final status = a['status']?.toString() ?? '';
            final notes = a['notes']?.toString() ?? '';

            Color statusColor;
            IconData statusIcon;
            switch (status) {
              case 'attended':
                statusColor = Colors.green;
                statusIcon = Icons.check_circle_outline;
                break;
              case 'missed':
                statusColor = Colors.red;
                statusIcon = Icons.cancel_outlined;
                break;
              default:
                statusColor = Colors.orange;
                statusIcon = Icons.swap_horiz_rounded;
            }

            final String statusLabel = status == 'attended'
                ? LocaleKeys.attended.tr()
                : status == 'missed'
                ? LocaleKeys.missed.tr()
                : status == 'otherLesson'
                ? LocaleKeys.other_lesson.tr()
                : status;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  // Status icon circle
                  Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: 0.15),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 20.r),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a['date']?.toString() ?? '',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notes.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          // Attendance type badge
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'attended'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: status == 'attended'
                                    ? Colors.green.withValues(alpha: 0.3)
                                    : Colors.orange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  status == 'attended'
                                      ? Icons.groups_outlined
                                      : Icons.swap_horiz_rounded,
                                  size: 12.r,
                                  color: status == 'attended'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    notes,
                                    style: TextStyle(
                                      fontSize: 8.sp,
                                      color: status == 'attended'
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
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
                    label: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 8.sp),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
